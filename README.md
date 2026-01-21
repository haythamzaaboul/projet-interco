# Projet Interconnexion Réseau

<div align="center">

![Network](https://img.shields.io/badge/Network-Infrastructure-blue?style=for-the-badge&logo=cisco)
![OSPF](https://img.shields.io/badge/Routing-OSPF-green?style=for-the-badge)
![Linux](https://img.shields.io/badge/OS-Linux-yellow?style=for-the-badge&logo=linux&logoColor=white)
![Bash](https://img.shields.io/badge/Scripts-Bash-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)
![Security](https://img.shields.io/badge/Security-iptables-red?style=for-the-badge&logo=fireship)

**Infrastructure réseau d'entreprise complète avec routage dynamique, segmentation, DMZ et services**

[Architecture](#-architecture-réseau) • [Technologies](#-stack-technologique) • [Fonctionnalités](#-fonctionnalités-clés) • [Installation](#-installation) • [Équipe](#-équipe)

</div>

---

## Présentation

Ce projet implémente une **infrastructure réseau d'entreprise complète** simulant un environnement de production réel. Conçu dans un contexte académique, il démontre la maîtrise des concepts fondamentaux de l'administration système et réseau.

L'architecture comprend **5 routeurs interconnectés**, une **zone démilitarisée (DMZ)** hébergeant des services critiques, et des **réseaux locaux segmentés** avec des politiques de sécurité granulaires.

### Ce qui rend ce projet unique

- **Infrastructure complète** : Pas un simple exercice théorique, mais une topologie fonctionnelle testée en conditions réelles
- **Routage dynamique OSPF** : Utilisation de Quagga pour un routage intelligent avec convergence automatique
- **Sécurité multicouche** : Firewall iptables, NAT, segmentation réseau et isolation des services
- **Services de production** : DNS (BIND9), Web (Apache2), FTP (vsftpd) configurés selon les bonnes pratiques
- **Automatisation complète** : Scripts Bash idempotents pour un déploiement reproductible
- **Documentation professionnelle** : Chaque composant est documenté et commenté

---

## Architecture Réseau

```
                           ┌─────────────────┐
                           │    INTERNET     │
                           └────────┬────────┘
                                    │
                    ┌───────────────┴───────────────┐
                    │     BOX PRIVÉE (Résidentiel)  │
                    │         120.0.64.5            │
                    │    NAT | DHCP | OSPF Area 1   │
                    └───────────────┬───────────────┘
                                    │
        ════════════════════════════╪════════════════════════════
                          120.0.64.0/24 (WAN - Area 2)
        ════════════════════════════╪════════════════════════════
                                    │
                    ┌───────────────┴───────────────┐
                    │      R13 - ROUTEUR CENTRAL    │
                    │  Router ID: 13.13.13.13       │
                    │     Backbone OSPF Multi-Area  │
                    └──────┬─────────────────┬──────┘
                           │                 │
        ═══════════════════╪═════════════════╪═══════════════════
                    120.0.65.0/24 (Transit - Area 1)
        ════════╦══════════╩═════════════════╩══════════╦════════
                ║                                       ║
        ┌───────┴───────┐                       ┌───────┴───────┐
        │  R7 - FIREWALL │                       │   R10 - BOX   │
        │  ID: 7.7.7.7   │                       │ ID: 10.10.10.10│
        │ Filtrage Strict │                       │   NAT + DHCP   │
        └───────┬───────┘                       └───────┬───────┘
                │                                       │
        ┌───────┴───────┐                       ┌───────┴───────┐
        │ 192.168.2.0/24 │                       │ 192.168.3.0/24 │
        │   LAN INTERNE  │                       │    LAN BOX     │
        │    Sécurisé    │                       │   Résidentiel  │
        └───────────────┘                       └───────────────┘

        ════════╩═══════════════════════════════════════════════
                ║
        ┌───────┴───────┐
        │   R9 - DMZ    │
        │  ID: 9.9.9.9  │
        │ Zone Services │
        └───────┬───────┘
                │
        ═══════╪═══════════════════════════════════════
             120.0.66.0/24 (DMZ)
        ═══════╪═══════════════════════════════════════
                │
    ┌───────────┼───────────┐
    │           │           │
┌───┴───┐   ┌───┴───┐   ┌───┴───┐
│  WEB  │   │  FTP  │   │  DNS  │
│Apache2│   │vsftpd │   │BIND9  │
│.66.2  │   │.66.5  │   │       │
└───────┘   └───────┘   └───────┘
```

### Segmentation Réseau

| Segment | CIDR | Rôle | Caractéristiques |
|---------|------|------|------------------|
| **WAN** | `120.0.64.0/24` | Connexion Internet | OSPF Area 2, Point d'entrée |
| **Transit** | `120.0.65.0/24` | Backbone interne | OSPF Area 1, Interconnexion |
| **DMZ** | `120.0.66.0/24` | Services exposés | Web, FTP, DNS isolés |
| **LAN Privé** | `192.168.0.0/21` | Box résidentielle | NAT, DHCP, accès Internet |
| **LAN Firewall** | `192.168.2.0/24` | Réseau sécurisé | Filtrage strict |
| **LAN Box** | `192.168.3.0/24` | Réseau utilisateurs | NAT, DHCP standard |

---

## Stack Technologique

<table>
<tr>
<td align="center" width="33%">

### Routage & Réseau
- **Quagga** (zebra + ospfd)
- **OSPF v2** Multi-Area
- **iptables** / Netfilter
- **NAT** Masquerading
- **dnsmasq** DHCP

</td>
<td align="center" width="33%">

### Services
- **Apache2** Web Server
- **BIND9** DNS Server
- **vsftpd** FTP Server
- **systemd** Service Management

</td>
<td align="center" width="33%">

### Sécurité
- Firewall stateful
- Segmentation VLAN
- Chroot jails (FTP)
- Filtrage par port/IP
- Isolation DMZ

</td>
</tr>
</table>

---

## Fonctionnalités Clés

### Routage Dynamique OSPF

Configuration multi-area avec convergence automatique :

```bash
# Extrait de configuration OSPF (R13 - Routeur Central)
router ospf
  ospf router-id 13.13.13.13
  network 120.0.65.0/24 area 1    # Transit
  network 120.0.64.0/24 area 2    # WAN
```

- **Area 1** : Réseau de transit interne
- **Area 2** : Connexion WAN
- **Convergence** : Recalcul automatique des routes en cas de panne

### Sécurité Firewall

Règles iptables granulaires sur les routeurs stratégiques :

```bash
# Blocage SSH depuis R10 vers la DMZ
iptables -A FORWARD -s 120.0.65.2 -d 120.0.66.0/24 -p tcp --dport 22 -j DROP

# Blocage protocoles VoIP (SIP, RTP, H.323)
iptables -A FORWARD -s 120.0.65.2 -p udp --dport 5060:5061 -j DROP
iptables -A FORWARD -s 120.0.65.2 -p udp --dport 10000:20000 -j DROP
```

### Services DMZ

| Service | IP | Port | Fonctionnalités |
|---------|-----|------|-----------------|
| **Web** | 120.0.66.2 | 80 | Application web interactive (notes, outils, jeux) |
| **FTP** | 120.0.66.5 | 21 | Mode passif, authentification locale, chroot |
| **DNS** | - | 53 | Résolution de noms, zones forward/reverse |

---

## Installation

### Prérequis

```bash
# Installation des paquets nécessaires
apt-get update && apt-get install -y \
    quagga \
    dnsmasq \
    iptables \
    apache2 \
    bind9 \
    vsftpd
```

### Déploiement Rapide

```bash
# 1. Cloner le repository
git clone https://github.com/votre-username/projet-interco.git
cd projet-interco

# 2. Configurer un routeur (exemple: R13 central)
sudo ./13v2.sh

# 3. Configurer le serveur DNS
sudo ./bind9_setup.sh mondomaine.local 120.0.66.2

# 4. Déployer le serveur Web
sudo ./8.sh

# 5. Configurer le serveur FTP
sudo ./serveurFTP.sh
sudo ./ftpfolderconfig
```

### Structure des Fichiers

```
projet-interco/
├── Routeurs OSPF
│   ├── 7.sh                    # Routeur Firewall (R7)
│   ├── 9.sh                    # Routeur DMZ (R9)
│   ├── 10.sh                   # Routeur Box (R10)
│   ├── 13v2.sh                 # Routeur Central (R13)
│   ├── config Box Privée.sh    # Box Résidentielle
│   └── routeur-ospf-64.sh      # Routeur WAN (R14)
│
├── Serveurs
│   ├── 8.sh                    # Configuration Apache2
│   ├── bind9_setup.sh          # Configuration BIND9
│   ├── serveurFTP.sh           # Installation vsftpd
│   ├── ftpcnfig.sh             # Config FTP anonyme
│   └── ftpfolderconfig         # Arborescence FTP
│
├── Application Web
│   └── index.html              # Interface web complète
│
├── Configuration
│   └── daemons                 # Config démons Quagga
│
└── Documentation
    ├── README.md
    └── organisation.md
```

---

## Compétences Démontrées

Ce projet met en évidence la maîtrise de :

| Domaine | Compétences |
|---------|-------------|
| **Administration Réseau** | Configuration IP, routage statique/dynamique, sous-réseaux, CIDR |
| **Protocoles** | OSPF, DHCP, DNS, FTP, HTTP, ICMP |
| **Sécurité** | Firewall, NAT, segmentation, DMZ, contrôle d'accès |
| **Scripting** | Automatisation Bash, gestion d'erreurs, idempotence |
| **Services Linux** | systemd, Apache2, BIND9, vsftpd, Quagga |
| **Troubleshooting** | Diagnostic réseau, analyse de logs, débogage |

---

## Dépannage

<details>
<summary><b>OSPF ne converge pas</b></summary>

```bash
# Vérifier le statut Quagga
systemctl status quagga

# Vérifier les voisins OSPF
vtysh -c "show ip ospf neighbor"

# Vérifier les interfaces
ip link show
ip addr show
```
</details>

<details>
<summary><b>DNS ne résout pas</b></summary>

```bash
# Valider la configuration
named-checkconf
named-checkzone mondomaine.local /etc/bind/db.mondomaine.local

# Tester la résolution
dig @127.0.0.1 www.mondomaine.local
```
</details>

<details>
<summary><b>FTP refuse les connexions</b></summary>

```bash
# Vérifier le service
systemctl status vsftpd

# Consulter les logs
tail -f /var/log/vsftpd.log

# Vérifier les ports passifs
ss -tlnp | grep vsftpd
```
</details>

---

## Équipe

<table>
<tr>
<td align="center">
<b>Haytham ZAABOUL</b><br>
<sub>Infrastructure & Routage & FTP & securité</sub>
</td>
<td align="center">
<b>Arthur Sauvezie</b><br>
<sub>Partie privé</sub>
</td>
<td align="center">
<b>Anas</b><br>
<sub>DNS & VOIP</sub>
</td>
<td align="center">
<b>Tristan</b><br>
<sub>Auth</sub>
</td>
<td align="center">
<b>Mohib</b><br>
<sub>VPN</sub>
</td>
</tr>
</table>

---

## Licence

Ce projet est réalisé dans un cadre académique. Libre d'utilisation pour l'apprentissage et la référence.

---

<div align="center">

**Projet réalisé avec passion pour l'infrastructure réseau**

*Infrastructure as Code • Automatisation • Sécurité*

</div>
