from setuptools import setup, Extension, find_packages
from platform import system
from Cython.Build import cythonize


if system() == "Windows":
    extra_compile_args = [
        "/fp:fast",
        # "/arch:AVX512",
        "/favor:INTEL64",
        "/O2", "/Ob2", "/GL",
        ]
    extra_link_args = [
        "/MACHINE:X64",
        "/LTCG",
        ]
    library_dir = "libtcy/msvc/Release"
else:
    extra_compile_args = [
        '-Ofast',
        '-march=native',
        '-ffast-math',
        '-fforce-addr',
        '-fprefetch-loop-arrays',
        "-flto",
        ]
    extra_link_args = []
    library_dir = "libtcy/cmake-build-debug"

extensions = [
    Extension(
        name="pesim.*",
        sources=["pesim/*.pyx"],
        extra_compile_args=extra_compile_args,
        extra_link_args=extra_link_args,
        ),
    ]

with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

setup(
    name="pesim",
    packages=find_packages(),
    version="0.9.5.0",
    setup_requires=["Cython"],
    author="Tefx",
    author_email="zhaomeng.zhu@gmail.com",
    url="https://github.com/Tefx/pesim",
    project_urls={
        'Documentation': "https://pesim.readthedocs.io",
        "Source Code": "https://github.com/Tefx/pesim",
        },
    description="A Minimalist Discrete Event Simulation Library in Python",
    long_description=long_description,
    long_description_content_type="text/markdown",
    classifiers=[
        "Programming Language :: Python :: 3",
        "Development Status :: 4 - Beta",
        "License :: OSI Approved :: GNU Lesser General Public License v3 (LGPLv3)",
        "Operating System :: OS Independent",
        "Topic :: Scientific/Engineering",
        ],
    ext_modules=cythonize(
        extensions,
        compiler_directives={
            # "embedsignature":   True,
            "profile":          False,
            "linetrace":        False,
            "cdivision":        True,
            "boundscheck":      False,
            "wraparound":       False,
            "initializedcheck": False,
            "language_level":   3,
            },
        annotate=True,
        ),
    package_data={
        "":["*.pxd"],
        },
    )
