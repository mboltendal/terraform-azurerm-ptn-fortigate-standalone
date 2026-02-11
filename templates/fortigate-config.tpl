config system global
    set hostname "FortiGate-Azure"
    set timezone 26
    set admin-sport 8443
    set setup-mode disable
end

config system interface
    edit "port1"
        set alias "wan"
        set role wan
        set mode dhcp
        set allowaccess ping https ssh
        set defaultgw enable
    next
    edit "port2"
        set alias "lan"
        set role lan
        set mode dhcp
        set allowaccess ping
        set defaultgw disable
    next
end

%{ if admin_ssh_key != null }
config system admin
    edit "${admin_username}"
        set ssh-public-key1 "${admin_ssh_key}"
    next
end
%{ endif }

config router static
    edit 1
        set gateway 169.254.169.254
        set device "port1"
    next
    edit 2
        set dst 168.63.129.16 255.255.255.255
        set gateway 169.254.169.254
        set device "port1"
    next
end

config system ha
    set mode standalone
end

config firewall policy
    edit 1
        set name "outbound-web-nat"
        set srcintf "port2"
        set dstintf "port1"
        set srcaddr "all"
        set dstaddr "all"
        set action accept
        set schedule "always"
        set service "HTTP" "HTTPS"
        set nat enable
        set logtraffic all
    next
end

config system probe-response
    set mode http-probe
    set http-probe-value OK
    set port 8008
end

config system settings
    set allow-subnet-overlap enable
end
