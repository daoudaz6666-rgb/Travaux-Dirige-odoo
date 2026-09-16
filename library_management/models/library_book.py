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
    state = fields.Selection([
        ('draft', 'Brouillon'),
        ('available', 'Disponible'),
        ('borrowed', 'Emprunte'),
        ('lost', 'Perdu'),
    ], string='Etat', default='draft')
    active = fields.Boolean(default=True)
    loan_ids = fields.One2many('library.loan', 'book_id', string='Emprunts')

    @api.constrains('isbn')
    def _check_isbn(self):
        for record in self:
            if record.isbn and len(record.isbn) not in (10, 13):
                raise ValidationError("L'ISBN doit contenir 10 ou 13 caracteres.")

    @api.onchange('author_id')
    def _onchange_author_id(self):
        if self.author_id and not self.name:
            self.name = 'Nouveau livre de ' + self.author_id.name

    def action_borrow(self, borrower_id, return_date=False):
        self.ensure_one()
        loan = self.env['library.loan'].create({
            'book_id': self.id,
            'borrower_id': borrower_id,
            'return_date': return_date,
            'state': 'borrowed',
        })
        self.write({'available': False, 'state': 'borrowed'})
        return loan

    def action_open_new_loan(self):
        self.ensure_one()
        return {
            'type': 'ir.actions.act_window',
            'name': 'Nouvel emprunt',
            'res_model': 'library.loan',
            'view_mode': 'form',
            'target': 'new',
            'context': {'default_book_id': self.id},
        }

    def action_archive_lost_books(self):
        from datetime import date, timedelta
        limit_date = date.today() - timedelta(days=180)
        books = self.search([
            ('lost', '=', True),
            ('lost_date', '<=', limit_date),
            ('active', '=', True),
        ])
        books.write({'active': False})
