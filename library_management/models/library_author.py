from odoo import models, fields

class LibraryAuthor(models.Model):
    _name = 'library.author'
    _description = 'Auteur de bibliotheque'

    name = fields.Char(string='Nom', required=True)
    biography = fields.Text(string='Biographie')
    birth_date = fields.Date(string='Date de naissance')
    book_ids = fields.One2many('library.book', 'author_id', string='Livres')
