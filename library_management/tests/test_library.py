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
