data = [
    {
        'name': 'Victor Hugo',
        'birth_date': '1802-02-26',
        'biography': "Ecrivain, poete et dramaturge francais du XIXe siecle, chef de file du romantisme.",
        'books': [
            {'name': 'Les Miserables', 'isbn': '9782253096344', 'publish_date': '1862-01-01'},
            {'name': 'Notre-Dame de Paris', 'isbn': '9782253009476', 'publish_date': '1831-01-01'},
        ],
    },
    {
        'name': 'Albert Camus',
        'birth_date': '1913-11-07',
        'biography': "Ecrivain, philosophe et journaliste francais ne en Algerie, prix Nobel 1957.",
        'books': [
            {'name': "L'Etranger", 'isbn': '9782070360024', 'publish_date': '1942-01-01'},
            {'name': 'La Peste', 'isbn': '9782070360420', 'publish_date': '1947-01-01'},
        ],
    },
    {
        'name': 'Gustave Flaubert',
        'birth_date': '1821-12-12',
        'biography': "Romancier francais, figure majeure du realisme.",
        'books': [
            {'name': 'Madame Bovary', 'isbn': '9782070413119', 'publish_date': '1857-01-01'},
        ],
    },
    {
        'name': 'Emile Zola',
       'birth_date': '1840-04-02',
        'biography': "Ecrivain francais, chef de file du naturalisme.",
        'books': [
            {'name': 'Germinal', 'isbn': '9782070413928', 'publish_date': '1885-01-01'},
        ],
    },
    {
        'name': 'Marcel Proust',
        'birth_date': '1871-07-10',
        'biography': "Romancier francais, auteur de A la recherche du temps perdu.",
        'books': [
            {'name': 'Du cote de chez Swann', 'isbn': '9782070408504', 'publish_date': '1913-01-01'},
        ],
    },
    {
        'name': 'Antoine de Saint-Exupery',
        'birth_date': '1900-06-29',
        'biography': "Ecrivain et aviateur francais, auteur du Petit Prince.",
        'books': [
            {'name': 'Le Petit Prince', 'isbn': '9782070612758', 'publish_date': '1943-01-01'},
        ],
    },
    {
        'name': 'Jean-Paul Sartre',
        'birth_date': '1905-06-21',
        'biography': "Philosophe et ecrivain francais, figure de l'existentialisme.",
        'books': [
            {'name': 'La Nausee', 'isbn': '9782070368372', 'publish_date': '1938-01-01'},
        ],
    },
    {
        'name': 'George Orwell',
        'birth_date': '1903-06-25',
        'biography': "Ecrivain britannique, connu pour ses critiques du totalitarisme.",
        'books': [
            {'name': '1984', 'isbn': '9782070368228', 'publish_date': '1949-01-01'},
        ],
    },
    {
        'name': 'Chinua Achebe',
        'birth_date': '1930-11-16',
        'biography': "Ecrivain nigerian, pere fondateur de la litterature africaine moderne.",
        'books': [
            {'name': "Le Monde s'effondre", 'isbn': '9782070364756', 'publish_date': '1958-01-01'},
        ],
    },
    {
        'name': 'Ahmadou Kourouma',
        'birth_date': '1927-11-24',
        'biography': "Ecrivain ivoirien, grand auteur de la litterature africaine francophone.",
        'books': [
            {'name': "Allah n'est pas oblige", 'isbn': '9782020420428', 'publish_date': '2000-01-01'},
        ],
    },
    {
        'name': 'Amadou Hampate Ba',
        'birth_date': '1900-05-01',
        'biography': "Ecrivain et ethnologue malien, figure de la tradition orale africaine.",
        'books': [
            {'name': "Amkoullel, l'enfant peul", 'isbn': '9782742718890', 'publish_date': '1991-01-01'},
        ],
    },
    {
        'name': 'Mariama Ba',
        'birth_date': '1929-04-17',
        'biography': "Ecrivaine senegalaise, autrice d'Une si longue lettre.",
        'books': [
            {'name': 'Une si longue lettre', 'isbn': '9782070384272', 'publish_date': '1979-01-01'},
        ],
    },
]
Author = env['library.author']
Book = env['library.book']

for entry in data:
    author = Author.search([('name', '=', entry['name'])], limit=1)
    if not author:
        author = Author.create({
            'name': entry['name'],
            'birth_date': entry['birth_date'],
            'biography': entry['biography'],
        })
        print("Auteur cree: " + entry['name'])
    else:
        print("Auteur deja present: " + entry['name'])

    for b in entry['books']:
        book = Book.search([('name', '=', b['name']), ('author_id', '=', author.id)], limit=1)
        if not book:
            Book.create({
                'name': b['name'],
                'isbn': b['isbn'],
                'publish_date': b['publish_date'],
                'author_id': author.id,
            })
            print("  Livre cree: " + b['name'])
        else:
            print("  Livre deja present: " + b['name'])

env.cr.commit()
print("Termine.")