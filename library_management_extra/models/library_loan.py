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
