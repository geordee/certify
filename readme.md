# Generate Certificates

Generate certificates, and optionally sign using a self-signed certificate.

## Install

This program requires Ruby in your system.

Install the required libraries

```bash
bundle install
```

## Configure

## Template
Review the template.jpg file in the images folder.
Modify the template.jpg file using an image editor, if required.

Please ensure to save the template.jpg at least 300DPI resolution to enable printing.
If you modify the file, please select the correct DPI while saving.

Also, make sure that the proportions of the template matches with the configured page size.

## Data
The student data is stored using the following convention.
The paths and prefixes may be tweaked using config.yml, however it is recommended not to.

```
data/grades/{grade}/sections/{section}.csv
```

The signatory details can be updated through config.yml

The certificate issued for, and issued date are also updated through config.yml

## Run

Run this program using the following command, in the terminal

```bash
bundle exec generate.rb
```

If the output is ```ruby: command not found```,
you may not have Ruby installed in your system.

## Sign

To sign and verify the certificates using a self-signed certificate,
perform the following steps.

### Generate Self-signed Certificate

Run the following commands to generate a self-signed certificate for digital signature.
Once generated, please store the private key and certificate securely.
The certificate is required for verification, later.

```bash
RUBYOPT=-W:no-deprecated bundle exec utils/keys.rb
```

### Digitally Sign PDF Files

To sign the PDF files run the following commands.

```bash
RUBYOPT=-W:no-deprecated bundle exec utils/sign.rb
```
### Verify the Digitally Signed PDFs

```bash
RUBYOPT=-W:no-deprecated bundle exec utils/verify.rb certificate.pdf
```
