from setuptools import setup, Extension
try:
    from Cython.Build import cythonize
except ImportError:
    ext_modules = [Extension('old_russian_unification.c', ['old_russian_unification.c'])]
else:
    ext_modules = cythonize('old_russian_unification.pyx')

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
    ext_modules=ext_modules
)
 
