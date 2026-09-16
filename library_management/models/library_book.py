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
