AC_DEFUN([AM_CHECK_RUBY_VERSION],
 [dnl # 
  dnl # Check the Ruby version
  dnl #
  REQUIRED_VERSION="$1"
  AC_MSG_CHECKING([ruby version...])
  RUBY_VERSION="`ruby -e "puts RUBY_VERSION"`"
  if ruby -e "exit(RUBY_VERSION >= '$REQUIRED_VERSION')" >/dev/null; then
    AC_MSG_RESULT($RUBY_VERSION found)
  else
    AC_MSG_RESULT($RUBY_VERSION found)
    AC_MSG_ERROR($REQUIRED_VERSION or later is needed)
  fi])

AC_DEFUN([AM_PATH_RUBY],
 [dnl # 
  dnl # Check Ruby directory
  dnl #
  AC_ARG_WITH(rubydir,
    [  --with-rubydir=DIR      ruby library files go to DIR [[guessed]]],
    [case "${withval}" in
       yes)	rubydir= ;;
       no)	AC_MSG_ERROR(rubydir is not available) ;;
       *)	rubydir=${withval} ;;
     esac], rubydir=)
  AC_MSG_CHECKING([where .rb files should go])
  if test "x$rubydir" = x; then
    changequote(<<, >>)
    rubydir=`ruby -rrbconfig -e 'puts Config::CONFIG["sitelibdir"]'`
    changequote([, ])
  fi
  AC_MSG_RESULT($rubydir)
  AC_SUBST(rubydir)

  AC_ARG_WITH(rubyarchdir,
    [  --with-rubyarchdir=DIR      ruby binary library files go to DIR [[guessed]]],
    [case "${withval}" in
       yes)	rubyarchdir= ;;
       no)	AC_MSG_ERROR(rubyarchdir is not available) ;;
       *)	rubyarchdir=${withval} ;;
     esac], rubyarchdir=)
  AC_MSG_CHECKING([where .rb files should go])
  if test "x$rubyarchdir" = x; then
    changequote(<<, >>)
    rubyarchdir=`ruby -rrbconfig -e 'puts Config::CONFIG["sitearchdir"]'`
    changequote([, ])
  fi
  AC_MSG_RESULT($rubyarchdir)
  AC_SUBST(rubyarchdir)

  changequote(<<, >>)
  RUBY_CC="`ruby -rmkmf -e 'puts Config::MAKEFILE_CONFIG["CC"]'`"
  RUBY_LDSHARED="`ruby -rmkmf -e 'puts Config::MAKEFILE_CONFIG["LDSHARED"]'`"
  RUBY_CFLAGS="`ruby -rmkmf -e 'puts Config::MAKEFILE_CONFIG["CFLAGS"]'`"
  RUBY_DLEXT="`ruby -rmkmf -e 'puts Config::MAKEFILE_CONFIG["DLEXT"]'`"
  RUBY_DLDFLAGS="`ruby -rmkmf -e 'puts Config::MAKEFILE_CONFIG["DLDFLAGS"]'`"
  RUBY_LIBS="`ruby -rmkmf -e 'puts Config::MAKEFILE_CONFIG["LIBS"]'`"
  RUBY_HDRHDIR="`ruby -rmkmf -e 'puts Config::CONFIG["archdir"]'`"
  RUBY_CPPFLAGS='-I. -I$(RUBY_HDRHDIR)'
  changequote([, ])

  AC_SUBST(RUBY_CC)
  AC_SUBST(RUBY_LDSHARED)
  AC_SUBST(RUBY_CFLAGS)
  AC_SUBST(RUBY_DLEXT)
  AC_SUBST(RUBY_DLDFLAGS)
  AC_SUBST(RUBY_LIBS)
  AC_SUBST(RUBY_HDRHDIR)
  AC_SUBST(RUBY_CPPFLAGS)
])


AC_DEFUN([AM_CHECK_RUBY_LIB],
 [dnl # 
  dnl # Check a library for Ruby
  dnl #
  LIB="$1"
  URL="$2"
  AC_MSG_CHECKING([$LIB for ruby...])
  if ruby -r$LIB -e '' 2>/dev/null; then
    AC_MSG_RESULT(found)
  else
    AC_MSG_RESULT(not found)
    if test "$URL"; then
        AC_MSG_RESULT($LIB is available at <$URL>)
    fi
    AC_MSG_ERROR($LIB for ruby not found)
  fi])


AC_DEFUN([AM_RUN_LOG_DIRS],
 [AC_ARG_WITH(
     rundir,
     [  --with-rundir=DIR       run time data direcotory [[/var/run]]],
     [RUNDIR=${withval}], [RUNDIR='/var/run']
 )
 AC_SUBST(RUNDIR)

 AC_ARG_WITH(
     logdir,
     [  --with-logdir=DIR       log directory [[/var/log]]],
     [LOGDIR=${withval}], [LOGDIR='/var/log']
 )
 AC_SUBST(LOGDIR)
])

AC_DEFUN([AM_USER_GROUP],
 [AC_ARG_WITH(
     user,
     [  --with-user=USER        use USER's UID in daemon mode [[root]]],
     [USER=${withval}], [USER='root']
 )
 AC_SUBST(USER)

 AC_ARG_WITH(
     group,
     [  --with-group=GROUP      use GROUP's GID in daemon mode [[root]]],
     [GROUP=${withval}], [GROUP='root']
 )
 AC_SUBST(GROUP)
])