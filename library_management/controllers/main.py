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
