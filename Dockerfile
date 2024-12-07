FROM ubuntu:20.04 AS build

RUN sed -i 's/archive.ubuntu.com/mirrors.ustc.edu.cn/g' /etc/apt/sources.list && \
    sed -i 's/security.ubuntu.com/mirrors.ustc.edu.cn/g' /etc/apt/sources.list

ENV TIME_ZONE Asia/Shanghai

RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends tzdata && \
    ln -sf /usr/share/zoneinfo/$TIME_ZONE /etc/localtime && \
    echo $TIME_ZONE > /etc/timezone && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends \
    ca-certificates pkg-config gnupg libgsl-dev \
    libpng-dev libxrender1 libfontconfig1 libxext6 \
    openssh-server openssh-client build-essential \
    csh ksh vim curl wget git autoconf automake make cmake \
    m4 unzip xz-utils file && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y gcc-10 gfortran-10 g++-10 && \
    cd /usr/bin && \
    ln -sf gfortran-10 gfortran && \
    ln -sf g++-10 g++ && \
    ln -sf gcc-10 gcc && \
    ln -sf gcc-ar-10 gcc-ar && \
    ln -sf gcc-nm-10 gcc-nm && \
    ln -sf gcc-ranlib-10 gcc-ranlib && \
    ln -sf gcov-10 gcov && \
    ln -sf gcov-dump-10 gcov-dump && \
    ln -sf gcov-tool-10 gcov-tool && \
    ln -sf cpp-10 cpp && \
    rm -rf /var/lib/apt/lists/*

ENV J 8
COPY libgfortran.tar.gz /tmp/

# install NCL
RUN cd /tmp && \
    wget https://www.earthsystemgrid.org/api/v1/dataset/ncl.662.dap/file/ncl_ncarg-6.6.2-Debian9.8_64bit_gnu630.tar.gz && \
    tar -zxvf ncl_ncarg-6.6.2-Debian9.8_64bit_gnu630.tar.gz -C /usr/local && \
    rm ncl_ncarg-6.6.2-Debian9.8_64bit_gnu630.tar.gz && \
    tar -zxvf libgfortran.tar.gz -C /usr/local/lib && \
    rm libgfortran.tar.gz && \
    cd /usr/local/lib && \
    ln -sf libgfortran.so.3.0.0 libgfortran.so.3

# install hdf5
RUN cd /tmp && \
    # install szip
    wget https://support.hdfgroup.org/ftp/lib-external/szip/2.1.1/src/szip-2.1.1.tar.gz && \
    tar -zxvf szip-2.1.1.tar.gz && \
    cd szip-2.1.1 && \
    ./configure --disable-dependency-tracking --prefix=/usr/local && \
    make install && \
    cd /tmp && \
    rm -rf szip-* && \
    # install zlib
    wget https://downloads.sourceforge.net/project/libpng/zlib/1.2.11/zlib-1.2.11.tar.gz && \
    tar -zxvf zlib-1.2.11.tar.gz && \
    cd zlib-1.2.11 && \
    ./configure --prefix=/usr/local && \
    make install && \
    cd /tmp && \
    rm -rf zlib-* && \
    # install hdf5
    wget https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.13/hdf5-1.13.0/src/hdf5-1.13.0.tar.gz && \
    tar -zxvf hdf5-1.13.0.tar.gz && \
    cd hdf5-1.13.0 && \
    cmake -B build -DCMAKE_INSTALL_PREFIX=/usr/local -DHDF5_ENABLE_Z_LIB_SUPPORT=ON -DHDF5_ENABLE_SZIP_SUPPORT=ON -DHDF5_BUILD_FORTRAN=ON && \
    cmake --build build --target install -- -j$J && \
    cd /tmp && \
    rm -rf hdf5-*

# install netcdf and pnetcdf
RUN cd /tmp && \
    # install netcdf-c
    wget https://downloads.unidata.ucar.edu/netcdf-c/4.8.1/netcdf-c-4.8.1.tar.gz && \
    tar -zxvf netcdf-c-4.8.1.tar.gz && \
    cd netcdf-c-4.8.1 && \
    ./configure --enable-netcdf-4 --enable-utilities --enable-shared --enable-static --disable-dap-remote-tests --disable-doxygen --enable-dap --prefix=/usr/local && \
    make -j$J install && \
    cd /tmp && \
    rm -rf netcdf-c-* && \
    # install netcdf-cxx
    wget https://downloads.unidata.ucar.edu/netcdf-cxx/4.3.1/netcdf-cxx4-4.3.1.tar.gz && \
    tar -zxvf netcdf-cxx4-4.3.1.tar.gz && \
    cd netcdf-cxx4-4.3.1 && \
    ./configure --disable-dependency-tracking --disable-dap-remote-tests --enable-static --enable-shared --prefix=/usr/local && \
    make -j$J install && \
    cd /tmp && \
    rm -rf netcdf-cxx4-* && \
    # install netcdf-fortran
    wget https://downloads.unidata.ucar.edu/netcdf-fortran/4.5.4/netcdf-fortran-4.5.4.tar.gz && \
    tar -zxvf netcdf-fortran-4.5.4.tar.gz && \
    cd netcdf-fortran-4.5.4 && \
    ./configure --disable-dependency-tracking --disable-dap-remote-tests --enable-static --enable-shared --prefix=/usr/local && \
    make -j$J install && \
    cd /tmp && \
    rm -rf netcdf-fortran-* && \
    # install openmpi
    wget https://download.open-mpi.org/release/open-mpi/v4.1/openmpi-4.1.3.tar.gz && \
    tar -zxvf openmpi-4.1.3.tar.gz && \
    cd openmpi-4.1.3 && \
    ./configure --disable-dependency-tracking --disable-silent-rules --disable-debug --enable-shared --with-hwloc=internal --prefix=/usr/local && \
    make all -j$J && make install && \
    cd /tmp && \
    rm -rf openmpi-* && ldconfig && \
    # install pnetcdf
    wget https://parallel-netcdf.github.io/Release/pnetcdf-1.12.3.tar.gz && \
    tar -zxvf pnetcdf-1.12.3.tar.gz && \
    cd pnetcdf-1.12.3 && \
    CC=gcc CXX=g++ F77=gfortran F90=gfortran FC=gfortran MPICC=mpicc MPICXX=mpicxx MPIF77=mpif77 MPIF90=mpif90 ./configure --prefix=/usr/local --enable-static --enable-shared && \
    make -j $J install && \
    cd /tmp && \
    rm -rf pnetcdf-*

# install eccodes
RUN cd /tmp && \
    # install openjpeg
    wget https://github.com/uclouvain/openjpeg/archive/refs/tags/v2.5.0.tar.gz && \
    mv v2.5.0.tar.gz openjpeg-2.5.0.tar.gz && \
    tar -zxvf openjpeg-2.5.0.tar.gz && \
    cd openjpeg-2.5.0 && \
    cmake -B build -DCMAKE_INSTALL_PREFIX=/usr/local && \
    cmake --build build --target install -- -j$J && \
    cd /tmp && \
    rm -rf openjpeg-* && \
    # install jpeg
    wget http://www.ijg.org/files/jpegsrc.v9d.tar.gz && \
    tar -zxvf jpegsrc.v9d.tar.gz && \
    cd jpeg-9d && \
    ./configure --disable-dependency-tracking --disable-silent-rules --prefix=/usr/local && \
    make -j$J install && \
    cd /tmp && \
    rm -rf jpeg* && \
    # install jasper
    wget http://www.ece.uvic.ca/~mdadams/jasper/software/jasper-1.900.1.zip && \
    unzip jasper-1.900.1.zip && \
    cd jasper-1.900.1 && \
    ./configure --disable-debug --disable-dependency-tracking --enable-shared --prefix=/usr/local && \
    make -j$J install && \
    cd /tmp && \
    rm -rf jasper-* && \
    # install ecbuild
    wget https://github.com/ecmwf/ecbuild/archive/refs/tags/3.6.5.tar.gz && \
    mv 3.6.5.tar.gz ecbuild-3.6.5.tar.gz && \
    tar -zxvf ecbuild-3.6.5.tar.gz && \
    cd ecbuild-3.6.5 && \
    cmake -B build -DCMAKE_INSTALL_PREFIX=/usr/local && \
    cmake --build build --target install && \
    cd /tmp && \
    rm -rf ecbuild-* && \
    # install eccodes
    wget https://github.com/ecmwf/eccodes/archive/refs/tags/2.26.0.tar.gz && \
    mv 2.26.0.tar.gz eccodes-2.26.0.tar.gz && \
    tar -zxvf eccodes-2.26.0.tar.gz && \
    cd eccodes-2.26.0 && \
    cmake -B build -DCMAKE_INSTALL_PREFIX=/usr/local -DENABLE_JPG=On -DENABLE_NETCDF=On -DENABLE_FORTRAN=On -DENABLE_AEC=OFF -DOPENJPEG_PATH=/usr/local -DJASPER_PATH=/usr/local -DNETCDF_PATH=/usr/local && \
    cmake --build build --target install -- -j$J && \
    cd /tmp && \
    rm -rf eccodes-*

# install cdo
RUN cd /tmp && \
    # install libxml2
    wget http://xmlsoft.org/sources/libxml2-2.9.7.tar.gz && \
    tar -zxvf libxml2-2.9.7.tar.gz && \
    cd libxml2-2.9.7 && \
    ./configure --disable-dependency-tracking --without-lzma --without-python --prefix=/usr/local && \
    make -j$J install && \
    cd /tmp && \
    rm -rf libxml2-* && \
    # install expat
    wget https://github.com/libexpat/libexpat/releases/download/R_2_4_1/expat-2.4.1.tar.xz && \
    tar -xvf expat-2.4.1.tar.xz && \
    cd expat-2.4.1 && \
    ./configure --prefix=/usr/local && \
    make -j$J install && \
    cd /tmp && \
    rm -rf expat-* && \
    # install udunits
    wget https://artifacts.unidata.ucar.edu/repository/downloads-udunits/2.2.28/udunits-2.2.28.tar.gz && \
    tar -zxvf udunits-2.2.28.tar.gz && \
    cd udunits-2.2.28 && \
    ./configure --prefix=/usr/local && \
    make -j$J install && \
    cd /tmp && \
    rm -rf udunits-* && \
    # install readline
    wget https://ftp.gnu.org/gnu/readline/readline-8.0.tar.gz && \
    tar -zxvf readline-8.0.tar.gz && \
    cd readline-8.0 && \
    ./configure --prefix=/usr/local && \
    make -j$J install && \
    cd /tmp && \
    rm -rf readline-* && \
    # install sqlite3
    wget https://sqlite.org/2020/sqlite-autoconf-3310100.tar.gz && \
    tar -zxvf sqlite-autoconf-3310100.tar.gz && \
    cd sqlite-autoconf-3310100 && \
    ./configure --disable-dependency-tracking --enable-dynamic-extensions --enable-readline --disable-editline --enable-session --prefix=/usr/local && \
    make -j$J install && \
    cd /tmp && \
    rm -rf sqlite-autoconf-* && \
    # install libtiff
    wget https://download.osgeo.org/libtiff/tiff-4.3.0.tar.gz && \
    tar -zxvf tiff-4.3.0.tar.gz && \
    cd tiff-4.3.0 && \
    ./configure --disable-dependency-tracking --disable-lzma --with-jpeg-include-dir=/usr/local/include --with-jpeg-lib-dir=/usr/local/lib --without-x --prefix=/usr/local && \
    make -j$J install && \
    cd /tmp && \
    rm -rf tiff-* && \
    # install proj
    wget https://download.osgeo.org/proj/proj-7.2.1.tar.gz && \
    tar -zxvf proj-7.2.1.tar.gz && \
    cd proj-7.2.1 && \
    ./configure --disable-dependency-tracking --without-curl --prefix=/usr/local && \
    make -j$J install && \
    cd /tmp && \
    rm -rf proj-* && \
    # install cdo
    wget https://code.mpimet.mpg.de/attachments/download/26823/cdo-2.0.5.tar.gz && \
    tar -zxvf cdo-2.0.5.tar.gz && \
    cd cdo-2.0.5 && \
    ./configure --disable-dependency-tracking --disable-debug --with-hdf5=/usr/local --with-netcdf=/usr/local --with-zlib=/usr/local --with-szlib=/usr/local --with-jasper=/usr/local --with-eccodes=/usr/local --with-udunits2=/usr/local --with-proj=/usr/local --with-libxml2=/usr/local --prefix=/usr/local && \
    make -j$J install && \
    cd /tmp && \
    rm -rf cdo-*

# install nco
RUN cd /tmp && \
    # install antlr2
    wget http://dust.ess.uci.edu/nco/antlr-2.7.7.tar.gz && \
    tar -zxvf antlr-2.7.7.tar.gz && \
    cd antlr-2.7.7 && \
    ./configure --disable-debug --disable-csharp --disable-java --disable-python --prefix=/usr/local && \
    make -j$J install && \
    cd /tmp && \
    rm -rf antlr-* && \
    # install gsl
    wget https://ftp.gnu.org/gnu/gsl/gsl-2.7.tar.gz && \
    tar -zxvf gsl-2.7.tar.gz && \
    cd gsl-2.7 && \
    ./configure --disable-dependency-tracking --prefix=/usr/local && \
    make -j$J && make install && \
    cd /tmp && \
    rm -rf gsl-* && \
    # install gettext
    wget https://ftp.gnu.org/gnu/gettext/gettext-0.19.8.1.tar.xz && \
    tar -xvf gettext-0.19.8.1.tar.xz && \
    cd gettext-0.19.8.1 && \
    ./configure --disable-dependency-tracking --disable-silent-rules --disable-debug --with-included-gettext --with-included-glib --with-included-libcroco --with-included-libunistring --disable-java --disable-csharp --without-git --without-cvs --without-xz --prefix=/usr/local && \
    make -j$J install && \
    cd /tmp && \
    rm -rf gettext-* && \
    # install flex
    wget https://github.com/westes/flex/releases/download/v2.6.4/flex-2.6.4.tar.gz && \
    tar -zxvf flex-2.6.4.tar.gz && \
    cd flex-2.6.4 && \
    ./configure --disable-dependency-tracking --disable-silent-rules --enable-shared --prefix=/usr/local && \
    make -j$J install && \
    cd /tmp && \
    rm -rf flex-* && \
    # install nco
    wget https://github.com/nco/nco/archive/refs/tags/5.0.7.tar.gz && \
    mv 5.0.7.tar.gz nco-5.0.7.tar.gz && \
    tar -zxvf nco-5.0.7.tar.gz && \
    cd nco-5.0.7 && \
    ./configure --enable-netcdf4 --enable-dap --enable-ncap2 --enable-udunits2 --disable-doc --prefix=/usr/local && \
    make -j$J install && \
    cd /tmp && \
    rm -rf nco-*

FROM ubuntu:20.04

RUN sed -i 's/archive.ubuntu.com/mirrors.ustc.edu.cn/g' /etc/apt/sources.list && \
    sed -i 's/security.ubuntu.com/mirrors.ustc.edu.cn/g' /etc/apt/sources.list

ENV TIME_ZONE Asia/Shanghai

RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends tzdata && \
    ln -sf /usr/share/zoneinfo/$TIME_ZONE /etc/localtime && \
    echo $TIME_ZONE > /etc/timezone && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends \
    ca-certificates pkg-config gnupg libgsl-dev \
    libpng-dev libxrender1 libfontconfig1 libxext6 \
    openssh-server openssh-client \
    csh ksh vim curl wget git autoconf automake make cmake \
    m4 unzip xz-utils file && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y gcc-10 gfortran-10 g++-10 && \
    cd /usr/bin && \
    ln -sf gfortran-10 gfortran && \
    ln -sf g++-10 g++ && \
    ln -sf gcc-10 gcc && \
    ln -sf gcc-ar-10 gcc-ar && \
    ln -sf gcc-nm-10 gcc-nm && \
    ln -sf gcc-ranlib-10 gcc-ranlib && \
    ln -sf gcov-10 gcov && \
    ln -sf gcov-dump-10 gcov-dump && \
    ln -sf gcov-tool-10 gcov-tool && \
    ln -sf cpp-10 cpp && \
    rm -rf /var/lib/apt/lists/*

COPY --from=build /usr/local/bin /usr/local/bin
COPY --from=build /usr/local/include /usr/local/include
COPY --from=build /usr/local/lib /usr/local/lib
COPY --from=build /usr/local/cmake /usr/local/cmake
COPY --from=build /usr/local/share /usr/local/share
COPY --from=build /usr/local/man /usr/local/man

RUN echo 'export NCARG_ROOT=/usr/local' >> /etc/bash.bashrc && \
    echo 'export NETCDF=/usr/local' >> /etc/bash.bashrc && \
    echo 'export NETCDF_ROOT=/usr/local' >> /etc/bash.bashrc && \
    echo 'export PNETCDF=/usr/local' >> /etc/bash.bashrc && \
    echo 'export JASPERLIB=/usr/local/lib' >> /etc/bash.bashrc && \
    echo 'export JASPERINC=/usr/local/include' >> /etc/bash.bashrc && \
    ldconfig

ENTRYPOINT ["/bin/sh", "-c", "tail -f /dev/null"]