from odoo import models, fields, api


class ResPartner(models.Model):
    _inherit = 'res.partner'

    cnib_number = fields.Char(string='Numero CNIB')
    library_member_number = fields.Char(string='Numero de carte membre', readonly=True, copy=False)

    @api.model_create_multi
    def create(self, vals_list):
        partners = super().create(vals_list)
        for partner in partners:
            if not partner.library_member_number:
                partner.library_member_number = self.env['ir.sequence'].next_by_code('library.member.number') or 'Nouveau'
        return partners
