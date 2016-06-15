##Bienvenidos al proyecto [Blackips] (http://www.blacklistweb.com)

En ocasiones hemos necesitado bloquear una dirección IP o un rango completo de IPs, relacionadas o no con sitios webs, spam, o de países de "dudosa reputación". Normalmente hacemos este bloqueo en el proxy o en el firewall (o en ambos) de forma manual o con una ACL. Pero qué sucedería si queremos neutralizar un país entero o varios cientos de miles (y a veces hasta millones) de ips. Hacerlo manualmente puede convertirse en un trabajo de tiempo completo.
Afortunadamente, el módulo [IPSET] (http://ipset.netfilter.org/) de [Netfilter[ (http://www.netfilter.org/) nos permite hacer este tipo de filtrado, ya sea con IPs, grandes bloques de CIDR o países enteros, en lo que se conoce como [Filtrado por Geolocalización] (http://www.maravento.com/2015/08/filtrado-por-geolocalizacion-ii.html), a una velocidad de procesamiento muy superior a otras soluciones de bloqueo masivo similares (Vea el [benchmark[ (http://daemonkeeper.net/781/mass-blocking-ip-addresses-with-ipset/))
Adicionalmente, muchos sitios nos brindan "listas negras" de IPs, sin embargo se pueden presentar situaciones en las que accidentalmente realicemos un bloqueo a una IP o rango CIDR que en realidad es legítimo.
El proyecto Blackips for [IPSET] (http://ipset.netfilter.org/) pretende crear una lista negra de IPs libre de falsos positivos. Para lograrlo, primero descarga varias listas negras (Vea "Ficha Técnica del Proyecto) listas "geozones" de [IPDeny] (http://www.ipdeny.com/ipblocks/) y otras listas negras reconocidas, para luego hace un filtrado, excluyendo aquellas ips que se encuentran en una "lista blanca" para finalmente utilizar la ACL resultante con el módulo [IPSET] (http://ipset.netfilter.org/) de iptables

**Modo de uso:**

Instale dependencias e ipset
```
sudo apt -y install git apt dpkg ipset
```
Descargue el repositorio:
```
git clone https://github.com/maravento/blackips
```
Copie el script a init.d y ejecútelo:
```
sudo cp blackips/blackips.sh /etc/init.d/blackips.sh
sudo chown root:root /etc/init.d/blackips.sh
sudo chmod +x /etc/init.d/blackips.sh
sudo /etc/init.d/blackips.sh
```
Programe su ejecución semanal en el cron:
```
sudo crontab -e
@weekly /etc/init.d/blackips.sh
```
Verifique la ejecución en /var/log/syslog.log:
```
<--| Blackips for Ipset: ejecucion 14/06/2016 15:47:14 |-->
```
Agregue las reglas Ipset a su script de iptables:
```
# Parametros
ipset=/sbin/ipset
iptables=/sbin/iptables

# BLACKZONE (select country to block and ip/range)
$ipset -F
$ipset -N -! blackzone hash:net maxelem 1000000
for ip in $(cat /etc/acl/blackips.txt); do
 $ipset -A blackzone $ip
done
iptables -t mangle -A PREROUTING -m set --match-set blackzone src -j DROP
iptables -A FORWARD -m set --match-set blackzone dst -j DROP
```
Adicionalmente puede bloquear rangos completos de países (ej: China y Rusia), reemplazando la línea por:
```
for ip in $(cat /etc/zones/{cn,ru}.zone /etc/acl/blackips); do
```
Para seleccionar varios países, visite [IPDeny] (http://www.ipdeny.com/ipblocks/)

**Muy Importante**

Los programas y reglas que se describen en este proyecto pueden consumir gran cantidad de recursos de su sistema. Su uso excesivo puede llevar al colapso de su servidor. Úselos con moderación.

**Ficha Técnica del Proyecto**

[IPDeny] (http://www.ipdeny.com/ipblocks/)

[Zeustracker] (https://zeustracker.abuse.ch/blocklist.php?download=badips)

[Ransomwaretracker] (https://ransomwaretracker.abuse.ch/downloads/RW_IPBL.txt)

[TOR exit addresses] (https://check.torproject.org/exit-addresses)

**Agradecimientos**

Agradecemos a todos los que han contribuido a este proyecto, en especial a [Netfilter] (http://www.netfilter.org/)

© 2016 [Blackips for Ipset] (http://www.blacklistweb.com) por [maravento] (http://www.maravento.com), es un componente del proyecto [Gateproxy] (http://www.gateproxy.com) y se distribuye bajo una [Licencia Creative Commons Atribución-NoComercial-CompartirIgual 4.0 Internacional] (http://creativecommons.org/licenses/by-nc-sa/4.0/). Basada en una obra en maravento. Permisos que vayan más allá de lo cubierto por esta licencia pueden encontrarse en maravento
