#!/bin/bash
set -e

echo ">>> Configuration Git"
git config --global user.name "Daouda ZONGO"
git config --global user.email "daoudaz6666@gmail.com"

echo ">>> Suppression eventuelle des anciens modules"
rm -rf ~/src/user/library_management
rm -rf ~/src/user/library_management_extra

echo ">>> Creation de la structure library_management"
mkdir -p ~/src/user/library_management/{models,views,security,data,controllers,tests,static/description}

# ---------------------------------------------------------------------------
# MANIFEST
# ---------------------------------------------------------------------------
cat > ~/src/user/library_management/__manifest__.py << 'EOF'
{
    'name': 'Library Management',
    'version': '1.0',
    'summary': 'Gestion de bibliotheque - TP Odoo',
    'category': 'Tools',
    'author': 'Daouda ZONGO',
    'depends': ['base', 'mail', 'website'],
    'data': [
        'security/library_security.xml',
        'security/ir.model.access.csv',
        'views/library_book_views.xml',
        'views/library_book_search.xml',
        'views/library_author_views.xml',
        'views/library_loan_views.xml',
        'views/library_menu.xml',
        'views/library_catalogue_template.xml',
        'data/library_book_server_action.xml',
        'data/library_loan_mail_template.xml',
        'data/library_loan_cron.xml',
        'data/library_loan_report_template.xml',
    ],
    'demo': [
        'data/library_demo.xml',
    ],
    'installable': True,
    'application': True,
    'license': 'LGPL-3',
}
EOF

cat > ~/src/user/library_management/__init__.py << 'EOF'
from . import models
from . import controllers
EOF

# ---------------------------------------------------------------------------
# MODELS
# ---------------------------------------------------------------------------
cat > ~/src/user/library_management/models/__init__.py << 'EOF'
from . import library_author
from . import library_book
from . import library_loan
EOF

cat > ~/src/user/library_management/models/library_author.py << 'EOF'
from odoo import models, fields

class LibraryAuthor(models.Model):
    _name = 'library.author'
    _description = 'Auteur de bibliotheque'

    name = fields.Char(string='Nom', required=True)
    biography = fields.Text(string='Biographie')
    birth_date = fields.Date(string='Date de naissance')
    book_ids = fields.One2many('library.book', 'author_id', string='Livres')
EOF

cat > ~/src/user/library_management/models/library_book.py << 'EOF'
from odoo import models, fields, api
from odoo.exceptions import ValidationError

class LibraryBook(models.Model):
    _name = 'library.book'
    _description = 'Livre de bibliotheque'

    name = fields.Char(string='Titre', required=True)
    isbn = fields.Char(string='ISBN')
    author_id = fields.Many2one('library.author', string='Auteur')
    publish_date = fields.Date(string='Date de publication')
    available = fields.Boolean(string='Disponible', default=True)
    lost = fields.Boolean(string='Perdu', default=False)
    lost_date = fields.Date(string='Date de perte')
    active = fields.Boolean(default=True)
    loan_ids = fields.One2many('library.loan', 'book_id', string='Emprunts')

    @api.constrains('isbn')
    def _check_isbn(self):
        for record in self:
            if record.isbn and len(record.isbn) not in (10, 13):
                raise ValidationError("L'ISBN doit contenir 10 ou 13 caracteres.")

    def action_archive_lost_books(self):
        from datetime import date, timedelta
        limit_date = date.today() - timedelta(days=180)
        books = self.search([
            ('lost', '=', True),
            ('lost_date', '<=', limit_date),
            ('active', '=', True),
        ])
        books.write({'active': False})
EOF

cat > ~/src/user/library_management/models/library_loan.py << 'EOF'
from odoo import models, fields, api

class LibraryLoan(models.Model):
    _name = 'library.loan'
    _inherit = ['mail.thread', 'mail.activity.mixin']
    _description = 'Emprunt de livre'

    book_id = fields.Many2one('library.book', string='Livre', required=True)
    author_id = fields.Many2one(related='book_id.author_id', string='Auteur', store=True, readonly=True)
    borrower = fields.Char(string='Emprunteur', required=True)
    loan_date = fields.Date(string="Date d'emprunt", default=fields.Date.context_today)
    return_date = fields.Date(string='Date de retour prevue')
    state = fields.Selection([
        ('draft', 'Brouillon'),
        ('borrowed', 'Emprunte'),
        ('returned', 'Retourne'),
    ], string='Statut', default='draft')

    @api.onchange('book_id')
    def _onchange_book_id(self):
        if self.book_id and self.book_id.author_id:
            self.author_id = self.book_id.author_id

    def action_borrow(self):
        for record in self:
            record.state = 'borrowed'
            record.book_id.available = False

    def action_return(self):
        for record in self:
            record.state = 'returned'
            record.book_id.available = True

    def cron_check_overdue_loans(self):
        from datetime import date
        today = date.today()
        overdue_loans = self.search([
            ('state', '=', 'borrowed'),
            ('return_date', '<', today),
        ])
        template = self.env.ref('library_management.mail_template_loan_reminder')
        for loan in overdue_loans:
            template.send_mail(loan.id, force_send=True)
            loan.message_post(body="Email de rappel envoye pour retard.")
EOF

# ---------------------------------------------------------------------------
# SECURITY
# ---------------------------------------------------------------------------
cat > ~/src/user/library_management/security/library_security.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<odoo>

    <record id="group_library_reader" model="res.groups">
        <field name="name">Lecteur</field>
    </record>

</odoo>
EOF

cat > ~/src/user/library_management/security/ir.model.access.csv << 'EOF'
id,name,model_id:id,group_id:id,perm_read,perm_write,perm_create,perm_unlink
access_library_author,library.author,model_library_author,base.group_user,1,1,1,1
access_library_book,library.book,model_library_book,base.group_user,1,1,1,1
access_library_loan,library.loan,model_library_loan,base.group_user,1,1,1,1
access_library_book_reader,library.book.reader,model_library_book,group_library_reader,1,0,0,0
EOF

# ---------------------------------------------------------------------------
# VIEWS
# ---------------------------------------------------------------------------
cat > ~/src/user/library_management/views/library_book_views.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<odoo>

    <record id="view_library_book_form" model="ir.ui.view">
        <field name="name">library.book.form</field>
        <field name="model">library.book</field>
        <field name="arch" type="xml">
            <form>
                <sheet>
                    <group>
                        <field name="name"/>
                        <field name="isbn"/>
                        <field name="author_id"/>
                        <field name="publish_date"/>
                        <field name="available"/>
                    </group>
                    <notebook>
                        <page string="Emprunts">
                            <field name="loan_ids"/>
                        </page>
                    </notebook>
                </sheet>
            </form>
        </field>
    </record>

    <record id="view_library_book_tree" model="ir.ui.view">
        <field name="name">library.book.tree</field>
        <field name="model">library.book</field>
        <field name="arch" type="xml">
            <list>
                <field name="name"/>
                <field name="author_id"/>
                <field name="isbn"/>
                <field name="available"/>
            </list>
        </field>
    </record>

    <record id="action_library_book" model="ir.actions.act_window">
        <field name="name">Livres</field>
        <field name="res_model">library.book</field>
        <field name="view_mode">list,form</field>
    </record>

</odoo>
EOF

cat > ~/src/user/library_management/views/library_book_search.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<odoo>

    <record id="view_library_book_search" model="ir.ui.view">
        <field name="name">library.book.search</field>
        <field name="model">library.book</field>
        <field name="arch" type="xml">
            <search>
                <field name="name"/>
                <field name="author_id"/>
                <filter string="Disponibles" name="filter_available" domain="[('available','=',True)]"/>
                <filter string="Non disponibles" name="filter_not_available" domain="[('available','=',False)]"/>
                <separator/>
                <filter string="Auteur" name="group_author" context="{'group_by':'author_id'}"/>
            </search>
        </field>
    </record>

</odoo>
EOF

cat > ~/src/user/library_management/views/library_author_views.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<odoo>

    <record id="view_library_author_form" model="ir.ui.view">
        <field name="name">library.author.form</field>
        <field name="model">library.author</field>
        <field name="arch" type="xml">
            <form>
                <sheet>
                    <group>
                        <field name="name"/>
                        <field name="birth_date"/>
                    </group>
                    <notebook>
                        <page string="Biographie">
                            <field name="biography"/>
                        </page>
                        <page string="Livres">
                            <field name="book_ids"/>
                        </page>
                    </notebook>
                </sheet>
            </form>
        </field>
    </record>

    <record id="view_library_author_tree" model="ir.ui.view">
        <field name="name">library.author.tree</field>
        <field name="model">library.author</field>
        <field name="arch" type="xml">
            <list>
                <field name="name"/>
                <field name="birth_date"/>
            </list>
        </field>
    </record>

    <record id="action_library_author" model="ir.actions.act_window">
        <field name="name">Auteurs</field>
        <field name="res_model">library.author</field>
        <field name="view_mode">list,form</field>
    </record>

</odoo>
EOF

cat > ~/src/user/library_management/views/library_loan_views.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<odoo>

    <record id="view_library_loan_form" model="ir.ui.view">
        <field name="name">library.loan.form</field>
        <field name="model">library.loan</field>
        <field name="arch" type="xml">
            <form>
                <header>
                    <button name="action_borrow" string="Emprunter" type="object"
                            class="btn-primary" invisible="state != 'draft'"/>
                    <button name="action_return" string="Retourner" type="object"
                            class="btn-secondary" invisible="state != 'borrowed'"/>
                    <field name="state" widget="statusbar"/>
                </header>
                <sheet>
                    <group>
                        <field name="book_id"/>
                        <field name="author_id"/>
                        <field name="borrower"/>
                        <field name="loan_date"/>
                        <field name="return_date"/>
                    </group>
                </sheet>
                <chatter/>
            </form>
        </field>
    </record>

    <record id="view_library_loan_tree" model="ir.ui.view">
        <field name="name">library.loan.tree</field>
        <field name="model">library.loan</field>
        <field name="arch" type="xml">
            <list>
                <field name="book_id"/>
                <field name="borrower"/>
                <field name="loan_date"/>
                <field name="return_date"/>
                <field name="state"/>
            </list>
        </field>
    </record>

    <record id="action_library_loan" model="ir.actions.act_window">
        <field name="name">Emprunts</field>
        <field name="res_model">library.loan</field>
        <field name="view_mode">list,form</field>
    </record>

</odoo>
EOF

cat > ~/src/user/library_management/views/library_menu.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<odoo>

    <menuitem id="menu_library_root" name="Bibliotheque" sequence="10"
              web_icon="library_management,static/description/icon.png"/>
    <menuitem id="menu_library_book" name="Livres" parent="menu_library_root"
              action="action_library_book" sequence="10"/>
    <menuitem id="menu_library_author" name="Auteurs" parent="menu_library_root"
              action="action_library_author" sequence="20"/>
    <menuitem id="menu_library_loan" name="Emprunts" parent="menu_library_root"
              action="action_library_loan" sequence="30"/>

</odoo>
EOF

cat > ~/src/user/library_management/views/library_catalogue_template.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<odoo>

    <template id="library_catalogue_template" name="Catalogue Bibliotheque">
        <t t-call="website.layout">
            <div class="container mt-4">
                <h1>Catalogue des livres disponibles</h1>
                <table class="table table-striped mt-3">
                    <thead>
                        <tr>
                            <th>Titre</th>
                            <th>Auteur</th>
                            <th>ISBN</th>
                        </tr>
                    </thead>
                    <tbody>
                        <t t-foreach="books" t-as="book">
                            <tr>
                                <td><span t-esc="book.name"/></td>
                                <td><span t-esc="book.author_id.name"/></td>
                                <td><span t-esc="book.isbn"/></td>
                            </tr>
                        </t>
                    </tbody>
                </table>
            </div>
        </t>
    </template>

</odoo>
EOF

# ---------------------------------------------------------------------------
# DATA
# ---------------------------------------------------------------------------
cat > ~/src/user/library_management/data/library_demo.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<odoo>
    <data noupdate="1">

        <record id="demo_author_hugo" model="library.author">
            <field name="name">Victor Hugo</field>
            <field name="birth_date">1802-02-26</field>
        </record>

        <record id="demo_author_camus" model="library.author">
            <field name="name">Albert Camus</field>
            <field name="birth_date">1913-11-07</field>
        </record>

        <record id="demo_book_miserables" model="library.book">
            <field name="name">Les Miserables</field>
            <field name="isbn">9780140444308</field>
            <field name="author_id" ref="demo_author_hugo"/>
            <field name="publish_date">1862-01-01</field>
        </record>

        <record id="demo_book_etranger" model="library.book">
            <field name="name">L'Etranger</field>
            <field name="isbn">9782070360024</field>
            <field name="author_id" ref="demo_author_camus"/>
            <field name="publish_date">1942-01-01</field>
        </record>

    </data>
</odoo>
EOF

cat > ~/src/user/library_management/data/library_book_server_action.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<odoo>

    <record id="action_archive_lost_books_server" model="ir.actions.server">
        <field name="name">Archiver les livres perdus depuis plus de 6 mois</field>
        <field name="model_id" ref="model_library_book"/>
        <field name="state">code</field>
        <field name="code">model.action_archive_lost_books()</field>
    </record>

</odoo>
EOF

cat > ~/src/user/library_management/data/library_loan_mail_template.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<odoo>

    <record id="mail_template_loan_reminder" model="mail.template">
        <field name="name">Rappel emprunt en retard</field>
        <field name="model_id" ref="model_library_loan"/>
        <field name="subject">Rappel : retour de votre emprunt en retard</field>
        <field name="email_to">{{ object.borrower }}</field>
        <field name="body_html" type="html">
            <p>Bonjour ${object.borrower},</p>
            <p>Nous vous rappelons que l'emprunt du livre
               "${object.book_id.name}" devait etre retourne le
               ${object.return_date}.</p>
            <p>Merci de le retourner dans les meilleurs delais.</p>
        </field>
    </record>

</odoo>
EOF

cat > ~/src/user/library_management/data/library_loan_cron.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<odoo>

    <record id="ir_cron_check_overdue_loans" model="ir.cron">
        <field name="name">Bibliotheque : verification emprunts en retard</field>
        <field name="model_id" ref="model_library_loan"/>
        <field name="state">code</field>
        <field name="code">model.cron_check_overdue_loans()</field>
        <field name="interval_number">1</field>
        <field name="interval_type">days</field>
        <field name="active">True</field>
    </record>

</odoo>
EOF

cat > ~/src/user/library_management/data/library_loan_report_template.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<odoo>

    <template id="report_library_loan_document">
        <t t-call="web.html_container">
            <t t-foreach="docs" t-as="doc">
                <t t-call="web.external_layout">
                    <div class="page">
                        <h2>Fiche d emprunt</h2>
                        <table class="table table-sm" style="margin-top: 20px;">
                            <tr>
                                <td><strong>Livre :</strong></td>
                                <td><span t-field="doc.book_id.name"/></td>
                            </tr>
                            <tr>
                                <td><strong>Auteur :</strong></td>
                                <td><span t-field="doc.author_id.name"/></td>
                            </tr>
                            <tr>
                                <td><strong>Emprunteur :</strong></td>
                                <td><span t-field="doc.borrower"/></td>
                            </tr>
                            <tr>
                                <td><strong>Date emprunt :</strong></td>
                                <td><span t-field="doc.loan_date"/></td>
                            </tr>
                            <tr>
                                <td><strong>Date retour prevue :</strong></td>
                                <td><span t-field="doc.return_date"/></td>
                            </tr>
                            <tr>
                                <td><strong>Statut :</strong></td>
                                <td><span t-field="doc.state"/></td>
                            </tr>
                        </table>
                    </div>
                </t>
            </t>
        </t>
    </template>

    <record id="action_report_library_loan" model="ir.actions.report">
        <field name="name">Fiche emprunt</field>
        <field name="model">library.loan</field>
        <field name="report_type">qweb-pdf</field>
        <field name="report_name">library_management.report_library_loan_document</field>
        <field name="report_file">library_management.report_library_loan_document</field>
        <field name="binding_model_id" ref="model_library_loan"/>
        <field name="binding_type">report</field>
    </record>

</odoo>
EOF

cat > ~/src/user/library_management/data/import_books_sample.csv << 'EOF'
name,isbn,author_id/name
La Peste,9782070360421,Albert Camus
Notre-Dame de Paris,9782253096337,Victor Hugo
EOF

# ---------------------------------------------------------------------------
# CONTROLLERS
# ---------------------------------------------------------------------------
cat > ~/src/user/library_management/controllers/__init__.py << 'EOF'
from . import main
EOF

cat > ~/src/user/library_management/controllers/main.py << 'EOF'
import json
from odoo import http
from odoo.http import request


class LibraryController(http.Controller):

    @http.route('/library/books/json', type='http', auth='public', website=True, csrf=False)
    def library_books_json(self, **kwargs):
        books = request.env['library.book'].sudo().search([('available', '=', True)])
        data = [{
            'name': book.name,
            'isbn': book.isbn,
            'author': book.author_id.name if book.author_id else '',
        } for book in books]
        return request.make_response(
            json.dumps(data),
            headers=[('Content-Type', 'application/json')]
        )

    @http.route('/library/catalogue', type='http', auth='public', website=True, csrf=False)
    def library_catalogue_page(self, **kwargs):
        books = request.env['library.book'].sudo().search([('available', '=', True)])
        return request.render('library_management.library_catalogue_template', {
            'books': books,
        })
EOF

# ---------------------------------------------------------------------------
# TESTS
# ---------------------------------------------------------------------------
cat > ~/src/user/library_management/tests/__init__.py << 'EOF'
from . import test_library
EOF

cat > ~/src/user/library_management/tests/test_library.py << 'EOF'
from odoo.tests.common import TransactionCase
from odoo.exceptions import ValidationError, AccessError


class TestLibrary(TransactionCase):

    def setUp(self):
        super().setUp()
        self.author = self.env['library.author'].create({
            'name': 'Auteur Test',
        })
        self.book = self.env['library.book'].create({
            'name': 'Livre Test',
            'isbn': '1234567890',
            'author_id': self.author.id,
        })
        self.loan = self.env['library.loan'].create({
            'book_id': self.book.id,
            'borrower': 'Emprunteur Test',
        })

    def test_action_borrow(self):
        self.loan.action_borrow()
        self.assertEqual(self.loan.state, 'borrowed')
        self.assertFalse(self.book.available)

    def test_isbn_constraint(self):
        with self.assertRaises(ValidationError):
            self.env['library.book'].create({
                'name': 'Livre ISBN invalide',
                'isbn': '123',
                'author_id': self.author.id,
            })

    def test_reader_access_denied(self):
        reader_group = self.env.ref('library_management.group_library_reader')
        reader_user = self.env['res.users'].create({
            'name': 'Lecteur Test',
            'login': 'lecteur_test',
            'group_ids': [(6, 0, [reader_group.id])],
        })
        with self.assertRaises(AccessError):
            self.env['library.book'].with_user(reader_user).create({
                'name': 'Livre non autorise',
                'author_id': self.author.id,
            })
EOF

# ---------------------------------------------------------------------------
# ICONE
# ---------------------------------------------------------------------------
echo ">>> Generation de l'icone"
python3 -c "
from PIL import Image
img = Image.new('RGB', (128, 128), color=(84, 132, 174))
img.save('/root/src/user/library_management/static/description/icon.png')
" 2>/dev/null || python3 -c "
from PIL import Image
img = Image.new('RGB', (128, 128), color=(84, 132, 174))
img.save('$HOME/src/user/library_management/static/description/icon.png')
"

# ---------------------------------------------------------------------------
# MODULE D'EXTENSION : library_management_extra
# ---------------------------------------------------------------------------
echo ">>> Creation du module library_management_extra"
mkdir -p ~/src/user/library_management_extra/models

cat > ~/src/user/library_management_extra/__manifest__.py << 'EOF'
{
    'name': 'Library Management Extra',
    'version': '1.0',
    'summary': 'Extension du module library_management - penalites de retard',
    'category': 'Tools',
    'author': 'Daouda ZONGO',
    'depends': ['library_management'],
    'data': [],
    'installable': True,
    'application': False,
    'license': 'LGPL-3',
}
EOF

cat > ~/src/user/library_management_extra/__init__.py << 'EOF'
from . import models
EOF

cat > ~/src/user/library_management_extra/models/__init__.py << 'EOF'
from . import library_loan
EOF

cat > ~/src/user/library_management_extra/models/library_loan.py << 'EOF'
from odoo import models, fields
from odoo.exceptions import ValidationError


class LibraryLoan(models.Model):
    _inherit = 'library.loan'

    late_fee = fields.Float(string='Penalite de retard', default=0.0)

    def action_borrow(self):
        for record in self:
            active_loans = self.search_count([
                ('borrower', '=', record.borrower),
                ('state', '=', 'borrowed'),
            ])
            if active_loans >= 3:
                raise ValidationError(
                    "Cet emprunteur a deja 3 emprunts en cours. "
                    "Limite atteinte."
                )
        return super().action_borrow()
EOF

echo ""
echo "======================================================="
echo "  TERMINE - structure complete creee avec succes"
echo "======================================================="
echo ""
echo "Verification des fichiers :"
find ~/src/user/library_management -type f | sort
echo ""
find ~/src/user/library_management_extra -type f | sort
echo ""
echo "Prochaine etape recommandee :"
echo "  cd ~/src/user"
echo "  git add -A"
echo "  git commit -m 'Reconstruction complete library_management + extra'"
echo "  odoo-update library_management"
