---
layout: post
title: Building a Python C extension module with CMake
subtitle: Extending Python, with automatic cross-platform configuration
image: /posts/img/cmake.svg
show-avatar: false
tags: [Python, CMake]
---

Python is a high-level programming language whose extremely simple and elegant
yet very powerful and expressive syntax has granted it enormous popularity in
most programming contexts. Scientific applications are no exception on this
respect, and this may look strange at a first glance, given that Python's
runtime is painfully slow and unsuitable for any high-performance computing,
and even elementary parallelism is [basically
undoable](https://en.wikipedia.org/wiki/Global_interpreter_lock) in pure Python
(or, at least, in its reference implementation,
[CPython](https://en.wikipedia.org/wiki/CPython)).

While Python's mainstream popularity is due to its high-level minimalism, the
strength behind its success in contexts where performance matters, such as most
scientific applications, is due to the extreme ease to invoke native library
calls from Python, thanks to the
[ctype](https://docs.python.org/3.7/library/ctypes.html) module, and to the
low-level [Python C API](https://docs.python.org/3.7/c-api/index.html), which
allows to easily write arbitrary C libraries (known as *Python C extension
modules*) whose members can be called directly from Python and behave mostly
like pure Python packages.

This post presents a brief overview of Python C extensions and the most common
tools available for their development, and it shows a way to build a C
extension using CMake to generate the configuration in a cross-platform
setting, using a concrete example from my work.

# Calling native functions from Python

If we want to use the C function `printf` within the Python REPL, we can do it
with the following three lines of code

```python
>>> from ctypes import CDLL
>>> libc = CDLL('libc.so.6') # The exact filename may vary on your system
>>> libc.printf(b"We compute %d + %d = %d!\n", 1, 2, 1 + 2)
```
whose output, unsurprisingly, is
```
We compute 1 + 2 = 3!
22
```
where `22` is the return value of the function, [corresponding to the
number of characters printed](https://www.gnu.org/software/libc/manual/html_node/Formatted-Output-Functions.html).

# Writing a Python C extension

While `ctypes` is a great tool for individual low level function calls, it is
not a practical solution to systematically wrap a large API. Here the Python C
API comes to the rescue, allowing to implement an arbitrarily complex module
directly in C. This of course allows to implement components in C++ as well, as
long as C linkage is used for the functions effectively called in the module.

The Python API can be accessed from the header `Python.h`, that should be
included with a CPython installation. The [official
documentation](https://docs.python.org/3/extending/index.html) contains a
[tutorial](https://docs.python.org/3/extending/extending.html) showing how to
structure the basics of a C extension. Here I am writing a very minimal
example, whose code should be pretty self-explanatory, implementing a module
that exports a single function to perform integer division.

```c
#include <Python.h>

// This is the definition of a method
static PyObject* division(PyObject *self, PyObject *args) {
    long dividend, divisor;
    if (!PyArg_ParseTuple(args, "ll", &dividend, &divisor)) {
        return NULL;
    }
    if (0 == divisor) {
        PyErr_Format(PyExc_ZeroDivisionError, "Dividing %d by zero!", dividend);
        return NULL;
    }
    return PyLong_FromLong(dividend / divisor);
}

// Exported methods are collected in a table
PyMethodDef method_table[] = {
    {"division", (PyCFunction) division, METH_VARARGS, "Method docstring"},
    {NULL, NULL, 0, NULL} // Sentinel value ending the table
};

// A struct contains the definition of a module
PyModuleDef mymath_module = {
    PyModuleDef_HEAD_INIT,
    "mymath", // Module name
    "This is the module docstring",
    -1,   // Optional size of the module state memory
    method_table,
    NULL, // Optional slot definitions
    NULL, // Optional traversal function
    NULL, // Optional clear function
    NULL  // Optional module deallocation function
};

// The module init function
PyMODINIT_FUNC PyInit_mymath(void) {
    return PyModule_Create(&mymath_module);
}
```

The module is defined in a standard [setup.py](https://docs.python.org/3.7/distutils/setupscript.html) script, here in a very minimal form. Calling the setup script allows to build, package, or install a Python module (regardless of the fact that it includes a C extension or not).

```python
from setuptools import setup, Extension

setup(name = "mymath",
      version = "0.1",
      ext_modules = [Extension("mymath", ["mymath.c"])]
      );
```

In case a C extension module is included, the source files specified in the
call to `setup()` will be automatically compiled when calling `python setup.py
build`: the Python interpreter will take care of invoking the C compiler with
proper flags and to link against the proper libraries.  The result is a shared
library: on Linux the file is called `mymath.cpython-37m-x86_64-linux-gnu.so`,
with a very self-explanatory file name; on Windows the extension is usually
`.pyd`. This shared object can be treated mostly as a pure Python module, and
it can be imported and used, for example from the Python REPL:

```
>>> import mymath
>>> mymath.division(4, 2)
2
>>> mymath.division(4, 0)
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
ZeroDivisionError: Dividing 4 by zero!
```

So far, everything is implemented in pristine C. Libraries such as
[pybind11](https://github.com/pybind/pybind11) and
[Boost.Python](https://www.boost.org/doc/libs/1_68_0/libs/python/doc/html/index.html)
simplify the creation of a Python extension module ex-novo in C++, handling all
the tedious parts related to the boilerplate code required to integrate with
the Python interpreter.

# Digression: Wrapping a library

While the Python C API is straightforward to use, the lack of high-level
functionalities in C can make it tedious to manually write some extensions,
especially when it boils down to write middleware to glue some pre-existing
library to an extension module.  However, many frameworks and automated tools
come to help. In particular, creating Python bindings for an existing C/C++
library is straightforward thanks to the [Simplified Wrapper and Interface
Generator (SWIG)](http://www.swig.org/), a tool that allows to generate a
Python API for an existing library interface in a mostly automatic fashion. As
a bonus, once SWIG is set up and in place it can also generate bindings for a
multitude of other languages, such as R, Perl, Java, C#, Ruby, and others.

# Building a Python extension

Python includes in its standard library the
[distutils](https://docs.python.org/3/library/distutils.html) package,
which handles the creation of Python modules and provides a portable
API to build native C extensions in a cross-platform setup. However, the
distutils package is usually not accessed directly, and most packagers use
an extended toolkit,
[setuptools](https://setuptools.readthedocs.io/en/latest/), that
provides a consistent interface for configuration, dependency handling,
and other simple and advanced features.

As seen before, distutils (and setuptools) can automatically build a Python
extension, taking care of invoking the compiler with suitable flags. This works
well for simple extensions without external dependencies, while for more
elaborated projects it may be necessary to use a custom extension builder, that
allows to tinker with the compiler settings and build options. This can be done
by creating a subclass of `setuptools.command.build_ext`, and then passing an
instance of this class to the `setup()` function.

```python
from setuptools import setup, Extension
from setuptools.command.build_ext import build_ext

class my_build_ext(build_ext):
    def build_extensions(self):
        if self.compiler.compiler_type == 'msvc':
            raise Exception("Visual Studio is not supported")

        for e in self.extensions:
            e.extra_compile_args = ['--pedantic']
            e.extra_link_args = ['-lgomp']

        build_ext.build_extensions(self)

setup(name = "mymath",
      version = "0.1",
      ext_modules = [Extension("mymath", ["mymath.c"])],
      cmdclass = {'build_ext': my_build_ext},
      );
```

# Building with CMake

For complex projects, however, this may not be enough, especially when large
libraries are involved. For instance, setting robust build options for a
cross-platform build of a CUDA or [ITK](https://itk.org/)-based application or
library can be a challenging task if done manually. This is when
[CMake](https://cmake.org/) comes into play. CMake is a cross-platform build
configuration generator tool, originally designed to build the ITK itself and
quickly adopted as one of the most popular build systems in the open-source
ecosystem. It allows to easily handle configuration, automatically discover
build settings for most of the common tools and libraries on different
platforms, and it allows to seamlessly integrate within a project any other
build dependency that uses CMake for its configuration.

Let assume we are building a C library with non-trivial dependencies, and that
we want to turn this library into a Python C extension module. As we have seen
so far, there is a wide variety of tools at our disposal for this purpose. If
our library is already configured with CMake, one option is to let CMake handle
the build of the Python extension module itself. After all, an extension module
is just a shared library that exports some specific symbols.

First of all, we ask CMake to find the Python interpreter and libs. We can
specify a minimum version if we want, which is 3.5 in this example.
```cmake
cmake_minimum_required(VERSION 3.10)
project(mymath)

find_package(PythonInterp 3.5 REQUIRED)

# This goes after, since it uses PythonInterp as hint
find_package(PythonLibs 3.5 REQUIRED)
```
In case we need to pass arrays forth and back between C and Python, the [NumPy C
API](https://docs.scipy.org/doc/numpy/reference/c-api.html) is probably the
best option. Once Python is ready, it is easy to locate the required NumPy
headers:
``` cmake
# This comes to hand if we also need to use the NumPy C API
exec_program(${PYTHON_EXECUTABLE}
             ARGS "-c \"import numpy; print(numpy.get_include())\""
             OUTPUT_VARIABLE NUMPY_INCLUDE_DIR
             RETURN_VALUE NUMPY_NOT_FOUND
            )
if(NUMPY_NOT_FOUND)
    message(FATAL_ERROR "NumPy headers not found")
endif()
```
Next we define a target for the extension itself. As said before, the extension
module is a shared library: here `${SRCS}` is the list of source files. It is
important to specify C linkage among the target properties.
```cmake
add_library(mymath SHARED ${SRCS})

set_target_properties(
    mymath
    PROPERTIES
        PREFIX ""
        OUTPUT_NAME "mymath"
        LINKER_LANGUAGE C
    )
```
At this point the extension is modeled as a regular CMake target, and this
allows to integrate it freely with other targets.

We may still want to let Python launch the build and take care of the
installation or packaging of our extension. To do this, we can write a custom
`build_ext` that launches the CMake build. For the sake of clarity, it is
possible to define a custom extension class that allows to specify the root
folder of the CMake project (`cmake_lists_dir`). Moreover, we set the `sources`
parameter to an empty list, since in the base class it is not an optional
argument, but we do not want setuptools to directly compile any file for us.
```python
class CMakeExtension(Extension):
    def __init__(self, name, cmake_lists_dir='.', **kwa):
        Extension.__init__(self, name, sources=[], **kwa)
        self.cmake_lists_dir = os.path.abspath(cmake_lists_dir)
```
We can then proceed to define the actual `build_ext` subclass that is in charge
to launch CMake.
```python
class cmake_build_ext(build_ext):
    def build_extensions(self):
        # Ensure that CMake is present and working
        try:
            out = subprocess.check_output(['cmake', '--version'])
        except OSError:
            raise RuntimeError('Cannot find CMake executable')

        for ext in self.extensions:

            extdir = os.path.abspath(os.path.dirname(self.get_ext_fullpath(ext.name)))
            cfg = 'Debug' if options['--debug'] == 'ON' else 'Release'

            cmake_args = [
                '-DCMAKE_BUILD_TYPE=%s' % cfg,
                # Ask CMake to place the resulting library in the directory
                # containing the extension
                '-DCMAKE_LIBRARY_OUTPUT_DIRECTORY_{}={}'.format(cfg.upper(), extdir),
                # Other intermediate static libraries are placed in a temporary
                # build directory instead
                '-DCMAKE_ARCHIVE_OUTPUT_DIRECTORY_{}={}'.format(cfg.upper(), self.build_temp),
                # Hint CMake to use the same Python executable that
                # is launching the build, prevents possible mismatching if
                # multiple versions of Python are installed
                '-DPYTHON_EXECUTABLE={}'.format(sys.executable),
                # Add other project-specific CMake arguments if needed
                # ...
            ]

            # We can handle some platform-specific settings at our discretion
            if platform.system() == 'Windows':
                plat = ('x64' if platform.architecture()[0] == '64bit' else 'Win32')
                cmake_args += [
                    # These options are likely to be needed under Windows
                    '-DCMAKE_WINDOWS_EXPORT_ALL_SYMBOLS=TRUE',
                    '-DCMAKE_RUNTIME_OUTPUT_DIRECTORY_{}={}'.format(cfg.upper(), extdir),
                ]
                # Assuming that Visual Studio and MinGW are supported compilers
                if self.compiler.compiler_type == 'msvc':
                    cmake_args += [
                        '-DCMAKE_GENERATOR_PLATFORM=%s' % plat,
                    ]
                else:
                    cmake_args += [
                        '-G', 'MinGW Makefiles',
                    ]

            cmake_args += cmake_cmd_args

            if not os.path.exists(self.build_temp):
                os.makedirs(self.build_temp)

            # Config
            subprocess.check_call(['cmake', ext.cmake_lists_dir] + cmake_args,
                                  cwd=self.build_temp)

            # Build
            subprocess.check_call(['cmake', '--build', '.', '--config', cfg],
                                  cwd=self.build_temp)
```

A real-life example of Python extension built this way is the
[disptools](https://github.com/m-pilia/disptools) (displacement-tools), a small
library for the generation of displacement fields with known volume changes,
that I implemented and made available on GitHub.

# Automating further

Additional support for scientific computing extensions is provided by
[scikit-build](https://github.com/scikit-build/scikit-build), a Python package
providing a build tool alternative to setuptools, that simplifies the build of
extensions written in C, C++, Cython, and Fortran. Scikit-build offers a bridge
between the `setup.py` and CMake, and it provides CMake modules to
automatically find Cython, NumPy, and F2PY.

