from odoo import http
from odoo.http import request


class LibraryWebsite(http.Controller):

    @http.route('/catalogue', type='http', auth='public', website=True, sitemap=True)
    def catalogue(self, **kwargs):
        books = request.env['library.book'].sudo().search([])
        return request.render('library_website.catalogue_page', {
            'books': books,
        })
