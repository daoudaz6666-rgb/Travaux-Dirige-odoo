from odoo import models, fields, api
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


class LibraryLoan(models.Model):
    _inherit = 'library.loan'

    LATE_FEE_PER_DAY = 500

    days_late = fields.Integer(string='Jours de retard', compute='_compute_late_fee')
    late_fee = fields.Float(string='Penalite de retard', compute='_compute_late_fee')

    @api.depends('return_date', 'state')
    def _compute_late_fee(self):
        from datetime import date
        today = date.today()
        for record in self:
            if record.state == 'borrowed' and record.return_date and record.return_date < today:
                record.days_late = (today - record.return_date).days
                record.late_fee = record.days_late * record.LATE_FEE_PER_DAY
            else:
                record.days_late = 0
                record.late_fee = 0.0
