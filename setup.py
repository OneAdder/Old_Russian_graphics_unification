from distutils.core import setup
from Cython.Build import cythonize

setup(
    name='old_russian_graphics_unification',
    version=0.1,
    description='A library for unification of Old Russian texts.',
    url='https://github.com/OneAdder/Old_Russian_graphics_unification',
    author="Michael Voronov, Anna Sorokina",
    author_email='mikivo@list.ru',
    license='GPLv3',
    python_requires='>=3.5',
    zip_safe=False,
    install_requires=['cython'],
    classifiers=[
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3 :: Only',
        'License :: OSI Approved :: GNU General Public License v3 (GPLv3)',
        'Topic :: Scientific/Engineering',
        'Topic :: Text Processing :: Linguistic',
        'Natural Language :: Russian',
    ],
    ext_modules = cythonize("old_russian_unification.pyx")
)
 
