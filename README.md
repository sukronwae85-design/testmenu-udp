Untuk file install-ssh-udp.sh:
1. Satu Baris dengan &&:
bash

wget https://raw.githubusercontent.com/sukronwae85-design/testmenu-udp/main/install-ssh-udp.sh && chmod +x install-ssh-udp.sh && bash install-ssh-udp.sh

2. Versi dengan -q (quiet mode):
bash

wget -q https://raw.githubusercontent.com/sukronwae85-design/testmenu-udp/main/install-ssh-udp.sh -O install-ssh-udp.sh && chmod +x install-ssh-udp.sh && bash install-ssh-udp.sh

3. Versi super pendek:
bash

wget -qO install-ssh-udp.sh https://raw.githubusercontent.com/sukronwae85-design/testmenu-udp/main/install-ssh-udp.sh && chmod +x install-ssh-udp.sh && bash install-ssh-udp.sh

4. Versi dengan sudo jika perlu:
bash

sudo wget -qO install-ssh-udp.sh https://raw.githubusercontent.com/sukronwae85-design/testmenu-udp/main/install-ssh-udp.sh && sudo chmod +x install-ssh-udp.sh && sudo bash install-ssh-udp.sh

5. Versi langsung sebagai root:
bash

sudo -i << 'EOF'
wget -q https://raw.githubusercontent.com/sukronwae85-design/testmenu-udp/main/install-ssh-udp.sh -O /root/install-ssh-udp.sh
chmod +x /root/install-ssh-udp.sh
bash /root/install-ssh-udp.sh
EOF

Jadi pilih salah satu yang sesuai kebutuhan Anda! 🚀
