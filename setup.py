from distutils.core import setup
from distutils.extension import Extension
from Cython.Build import cythonize
from platform import system

if system() == "Windows":
    extra_compile_args = [
        "-fp:fast",
        "/arch:AVX2",
        "/favor:INTEL64",
        "/Ox", "/Ob2", "/Oi", "/Ot", "/Oy", "/GL", "/GT",
        ]
    library_dir = "libtcy/msvc/Release"
else:
    extra_compile_args = [
        # '-O0',
        # '-g',
        '-Ofast',
        '-march=native',
        '-ffast-math',
        '-fforce-addr',
        '-fprefetch-loop-arrays',
        "-flto",
        ]
    library_dir = "libtcy/cmake-build-debug"

extensions = [
    Extension(
        name="pesim.*",
        sources=["pesim/*.pyx"],
        extra_compile_args=extra_compile_args,
        ),
    ]

setup(ext_modules=cythonize(
    extensions,
    compiler_directives={
        "profile":          True,
        "linetrace":        False,
        "cdivision":        True,
        "boundscheck":      False,
        "wraparound":       False,
        "initializedcheck": False,
        "language_level":   3,
        },
    annotate=True,
    ))