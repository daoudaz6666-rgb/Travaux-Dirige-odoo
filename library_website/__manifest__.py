{
    'name': 'Library Website',
    'version': '1.0',
    'summary': "Site web de la Bibliothèque Box Africa",
    'category': 'Website',
    'author': 'Daouda ZONGO',
    'license': 'LGPL-3',
    'depends': ['website', 'library_management'],
    'data': [
        'data/website_data.xml',
        'views/website_templates.xml',
    ],
    'installable': True,
    'application': False,
}
