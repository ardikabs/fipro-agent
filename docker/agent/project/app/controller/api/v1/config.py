
# configuration for sensor

glastopf_ports={
    '80/tcp': 80
}
cowrie_ports={
    '2222/tcp': 22,
    '2223/tcp': 23
}
dionaea_ports={
    '20/tcp': 20,
    '21/tcp': 21,
    '42/tcp': 42,
    '69/udp': 69,
    '135/tcp': 135,
    '443/tcp': 443,
    '445/tcp': 445,
    '1433/tcp': 1433,
    '1723/tcp': 1723,
    '1883/tcp': 1883,
    '3306/tcp': 3306,
    '5060/udp': 5060,
    '5061/tcp': 5061,
    '27017/tcp': 27017
}
dionaea_volumes={
    '/var/fipro/data/dionaea': {'bind': '/opt/dionaea/var/dionaea', 'mode': 'rw'}
}
cowrie_volumes={
    '/var/fipro/data/cowrie/keys': {'bind': '/home/cowrie/cowrie/etc', 'mode': 'rw'},
    '/var/fipro/data/cowrie/downloads': {'bind': '/home/cowrie/cowrie/dl', 'mode': 'rw'},
    '/var/fipro/data/cowrie/log': {'bind': '/home/cowrie/cowrie/log', 'mode': 'rw'},
    '/var/fipro/data/cowrie/log/tty': {'bind': '/home/cowrie/cowrie/log/tty', 'mode': 'rw'}
}
glastopf_volumes={
    '/var/fipro/data/glastopf/db': {'bind': '/opt/glastopf/db', 'mode': 'rw'},
    '/var/fipro/data/glastopf/log': {'bind': '/opt/glastopf/log', 'mode': 'rw'}
}

container_attributes={
    "dionaea": {"ports": dionaea_ports, "volumes": dionaea_volumes},
    "cowrie": {"ports": cowrie_ports, "volumes": cowrie_volumes},
    "glastopf": {"ports": glastopf_ports, "volumes": glastopf_volumes}
}