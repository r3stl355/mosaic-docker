FROM databricksruntime/standard:12.2-LTS

ENV ROOTDIR /usr/local
ENV LD_LIBRARY_PATH /usr/local/lib
ENV SPARK_VERSION 3.3.2

WORKDIR $ROOTDIR/
RUN mkdir -p $ROOTDIR/src

# Install dependencies
RUN set -ex \
    && deps=" \
	unixodbc \
	libcurl3-gnutls \
	libsnappy-dev \
	libopenjp2-7-dev \
#       python-dev \
#       python3-dev \
#       python3-numpy \
#       python3-pip \
#       python3-venv \
       bash-completion \
    " \
    && buildDeps=" \
       build-essential \
       cmake \
       swig \
       ant \
       pkg-config \
    "\
    && apt-get update -y && apt-get install -y $buildDeps $deps --no-install-recommends

# Add Maven
ARG MAVEN_VERSION=3.9.4
ARG USER_HOME_DIR="/root"
ARG BASE_URL=https://dlcdn.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries
ARG SHA=deaa39e16b2cf20f8cd7d232a1306344f04020e1f0fb28d35492606f647a60fe729cc40d3cba33e093a17aed41bd161fe1240556d0f1b80e773abd408686217e

RUN mkdir -p $ROOTDIR/share/maven $ROOTDIR/share/maven/ref \
  && echo "Downlaoding maven" \
  && curl -fsSL -o /tmp/apache-maven.tar.gz ${BASE_URL}/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
  \
  && echo "Checking download hash" \
  && echo "${SHA}  /tmp/apache-maven.tar.gz" | sha512sum -c - \
  \
  && echo "Unziping maven" \
  && tar -xzf /tmp/apache-maven.tar.gz -C $ROOTDIR/share/maven --strip-components=1 \
  \
  && echo "Cleaning and setting links" \
  && rm -f /tmp/apache-maven.tar.gz \
  && ln -s $ROOTDIR/share/maven/bin/mvn $ROOTDIR/bin/mvn

ENV MAVEN_HOME $ROOTDIR/share/maven
ENV MAVEN_CONFIG "$USER_HOME_DIR/.m2"

# Configure Python virtual environment
RUN pip install pip --upgrade
RUN pip install build wheel pyspark==$SPARK_VERSION

# We add RStudio's debian source to install the latest r-base version (4.1)
# We are using the more secure long form of pgp key ID of marutter@gmail.com
# based on these instructions (avoiding firewall issue for some users):
# https://cran.rstudio.com/bin/linux/ubuntu/#secure-apt
RUN apt-get update \
  && apt-get install --yes software-properties-common apt-transport-https \
  && gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9 \
  && gpg -a --export E298A3A825C0D65DFD57CBB651716619E084DAB9 | sudo apt-key add - \
  && add-apt-repository -y "deb [arch=amd64,i386] https://cran.rstudio.com/bin/linux/ubuntu $(lsb_release -cs)-cran40/" \
  && apt-get update \
  && apt-get install --yes \
    libssl-dev \
    r-base \
    r-base-dev \
  && add-apt-repository -r "deb [arch=amd64,i386] https://cran.rstudio.com/bin/linux/ubuntu $(lsb_release -cs)-cran40/" \
  && apt-key del E298A3A825C0D65DFD57CBB651716619E084DAB9 \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# hwriterPlus is used by Databricks to display output in notebook cells
# hwriterPlus is removed for newer version of R, so we hardcode the dependency to archived version
# Rserve allows Spark to communicate with a local R process to run R code
RUN R -e "options(repos = list(CRAN = 'https://cloud.r-project.org/')); install.packages(c('hwriter', 'TeachingDemos', 'htmltools'))" \
 && R -e "install.packages('https://cran.r-project.org/src/contrib/Archive/hwriterPlus/hwriterPlus_1.0-3.tar.gz', repos=NULL, type='source')" \
 && R -e "install.packages('Rserve', repos='http://rforge.net/')"

# Additional instructions to setup rstudio. If you dont need rstudio, you can
# omit the below commands in your docker file. Even after this you need to use
# an init script to start the RStudio daemon (See README.md for details.)

# Databricks configuration for RStudio sessions.
COPY Rprofile.site /usr/lib/R/etc/Rprofile.site

# Rstudio installation.
RUN apt-get update \
 # Install gdebi-core.
 && apt-get install -y gdebi-core \
 # Download rstudio 1.4 package for ubuntu 18.04 and install it.
 && apt-get install -y wget \
 && apt-get install -y gdebi-core \
 && wget https://download2.rstudio.org/server/bionic/amd64/rstudio-server-2022.02.1-461-amd64.deb \
 && gdebi -n rstudio-server-2022.02.1-461-amd64.deb && rstudio-server version

# Clean up
RUN apt-get purge -y --auto-remove $buildDeps \
    && rm -rf /var/lib/apt/lists/*
