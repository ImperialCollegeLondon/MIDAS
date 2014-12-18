HICF website
============

Front end for the HICF pathogen genome store.

1. Install prerequisites:

  * [node.js](http://nodejs.org/)
  * [sass](http://sass-lang.com/)

2. Clone the repo

  ```
  git clone https://github.com/sanger-pathogens/MIDAS.git
  ```

3. Install node packages

  ```bash
  cd MIDAS
  npm install
  ```

  (before running "npm install" you need to configure proxies:

  ```bash
  export http_proxy=http://<proxy host>:<proxy port>
  export https_proxy=http://<proxy host>:<proxy port>
  ```

  otherwise downloading packages through the firewall fails.)

  You may need to install `grunt-cli` as a global package:

  ```bash
  npm install -g grunt-cli
  ```

