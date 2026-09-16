from odoo import models
from odoo.exceptions import ValidationError


class LibraryBook(models.Model):
    _inherit = 'library.book'

    def action_borrow(self, borrower_id, return_date=False):
        Loan = self.env['library.loan']
        active_loans = Loan.search_count([
            ('borrower_id', '=', borrower_id),
            ('state', '=', 'borrowed'),
        ])
        if active_loans >= 3:
            raise ValidationError(
                "Cet emprunteur a deja 3 emprunts en cours. "
                "Limite atteinte."
            )
        return super().action_borrow(borrower_id, return_date=return_date)
