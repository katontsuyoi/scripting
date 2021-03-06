#!/bin/bash
read -p 'masukkan nama Domain Baru : ' domain

sudo echo '*@$domain       default._domainkey.$domain' >> /etc/opendkim/signing.table
echo 'Menambahkan domain $domain ke Signing.table >>> DONE' 

sudo echo 'default._domainkey.$domain     $domain:default:/etc/opendkim/keys/$domain/default.private' >> /etc/opendkim/key.table
echo 'Menambahkan domain $domain ke Key.table >>> DONE'

sudo echo '*.$domain' >> /etc/opendkim/trusted.hosts
echo 'Menambahkan domain $domain ke Trusted.table >>> DONE'

sudo mkdir /etc/opendkim/keys/$domain
echo 'Memebuat direktori $domain >>> DONE'

sudo opendkim-genkey -b 2048 -d $domain -D /etc/opendkim/keys/$domain -s default -v
echo 'Membuat dkim untuk $domain >>> DONE'

sudo chown opendkim:opendkim /etc/opendkim/keys/$domain/default.private
echo 'Pemberian Hak Akses untuk domain $domain >>> DONE'

sudo touch /etc/apache2/sites-available/mail.$domain.conf
sudo cat > /etc/apache2/sites-available/mail.$domain.conf << EOF
<VirtualHost *:80>
  ServerName mail.$domain
  DocumentRoot /var/www/html/

  ErrorLog ${APACHE_LOG_DIR}/mail.$domain_error.log
  CustomLog ${APACHE_LOG_DIR}/mail.$domain_access.log combined

  <Directory />
    Options FollowSymLinks
    AllowOverride All
  </Directory>

  <Directory /var/www/html/>
    Options FollowSymLinks MultiViews
    AllowOverride All
    Order allow,deny
    allow from all
  </Directory>

</VirtualHost>
EOF
sudo a2ensite mail.$domain.conf
echo 'Selamat pendaftaran Web mail.$domain sudah berhasil !'
sudo systemctl restart apache2 dovecot postfix opendkim
echo 'Restart service berhasil'
echo 'Setting sudah selesai tinggal ikuti langkah dibawah ini'

sudo cat /etc/opendkim/keys/$domain/default.txt
echo -e 'COPY text diatas ke DNS Management dengan format : \nTYPE: TXT \nNAME: default._domainkey \nTTL: BEBAS \nCONTENT: masukkan data diatas TANPA SPASI dan PETIK2'
echo '##############################################################################'
echo -e 'Kemudian buat lagi untuk dmarc $domain  \nTYPE: TXT \nNAME: _dmarc \nCONTENT: v=DMARC1;p=none;pct=100;rua=mailto:report@$domain \nBuatlah email dengan format report@$domain' 
echo '##############################################################################'
echo 'Isi di DNS Managemenet $domain  \nTYPE: MX \nNAME: @ \nCONTENT: mail.$domain'
echo 'Isi di DNS Managemenet $domain  \nTYPE: A \nNAME: mail \nCONTENT: IP-Address'
echo 'Isi di DNS Managemenet $domain  \nTYPE: TXT \nNAME: @ \nCONTENT: v=spf1 mx ~all'
echo 'silahkan membuat certificate sudo certbot --apache --agree-tos --redirect --hsts --staple-ocsp -d mail.devlmu.com,mail.simotor.id,mail.$domain --cert-name mail.devlmu.com --email katontsuyoi@gmail.com'
