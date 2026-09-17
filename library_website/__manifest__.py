{
    'name': 'Library Website',
    'version': '1.0',
    'summary': "Site web de la Bibliothèque Box Africa",
    'category': 'Website',
    'depends': ['website', 'library_management'],
    'data': [
        'data/website_data.xml',
        'views/website_templates.xml',
    ],
    'installable': True,
    'application': False,
}
