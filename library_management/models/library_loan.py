from odoo import models, fields, api

class LibraryLoan(models.Model):
    _name = 'library.loan'
    _inherit = ['mail.thread', 'mail.activity.mixin']
    _description = 'Emprunt de livre'

    book_id = fields.Many2one('library.book', string='Livre', required=True)
    author_id = fields.Many2one(related='book_id.author_id', string='Auteur', store=True, readonly=True)
    borrower = fields.Char(string='Emprunteur', required=True)
    loan_date = fields.Date(string="Date d'emprunt", default=fields.Date.context_today)
    return_date = fields.Date(string='Date de retour prevue')
    state = fields.Selection([
        ('draft', 'Brouillon'),
        ('borrowed', 'Emprunte'),
        ('returned', 'Retourne'),
    ], string='Statut', default='draft')

    @api.onchange('book_id')
    def _onchange_book_id(self):
        if self.book_id and self.book_id.author_id:
            self.author_id = self.book_id.author_id

    def action_borrow(self):
        for record in self:
            record.state = 'borrowed'
            record.book_id.available = False

    def action_return(self):
        for record in self:
            record.state = 'returned'
            record.book_id.available = True

    def cron_check_overdue_loans(self):
        from datetime import date
        today = date.today()
        overdue_loans = self.search([
            ('state', '=', 'borrowed'),
            ('return_date', '<', today),
        ])
        template = self.env.ref('library_management.mail_template_loan_reminder')
        for loan in overdue_loans:
            template.send_mail(loan.id, force_send=True)
            loan.message_post(body="Email de rappel envoye pour retard.")
