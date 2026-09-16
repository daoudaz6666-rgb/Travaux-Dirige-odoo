from odoo import models, fields, api

class LibraryAuthor(models.Model):
    _name = 'library.author'
    _description = 'Auteur de bibliotheque'

    name = fields.Char(string='Nom', required=True)
    biography = fields.Text(string='Biographie')
    birth_date = fields.Date(string='Date de naissance')
    book_ids = fields.One2many('library.book', 'author_id', string='Livres')
    book_count = fields.Integer(string='Nombre de livres', compute='_compute_book_count')

    @api.depends('book_ids')
    def _compute_book_count(self):
        for record in self:
            record.book_count = len(record.book_ids)
