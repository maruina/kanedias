from digitalocean import Manager, Droplet, SSHKey

CLIENT_ID = "92fcbd1cbd8a49fa1701af5fb2b4b22c"
API_KEY = "079d3af8375a07a1176fb666c3e4c05b"
SSH_KEY_PUB = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC+HUxtHUeXdO3/8tWXMv3vVzddCuUzrX1MSdFU5H16508BRiRm6kx4ifslqhaj8+551lKtYmY+g7LI/zguw+Nwb8aAC2Riy+Dt63GHK8fEXsxsL+ndSXE2jhBgPGT4BOtJi1Xem3mW8AxehMHU/8ecNLoW58HaCvanTYL/j8inoFj2Bf5f5tE87K0px+Fd/l316DDB4eNI4+3TfrQTvtGuCQP5lvL8GJuLKiwv4nZurVcF1jxslzDv/sSF7D6LGsAZDvIXQKtMNSBlc7urq6h1x2yn6lpnnyr7lNPW8iC0M4k+5PZd2shUfsiYpTNpIxFbbzKsPPfLyqY6Og8HLcBz maruina@github.com"

if __name__ == '__main__':
    manager = Manager(client_id=CLIENT_ID, api_key=API_KEY)
    images = manager.get_all_images()
    regions = manager.get_all_regions()
    sizes = manager.get_all_sizes()
    print [region.name for region in regions]
    print ""
    print [size.name for size in sizes]
    ssh_keys = manager.get_all_sshkeys()

    for ssh_key in ssh_keys:
        ssh_key.load()
        if SSH_KEY_PUB in ssh_key.ssh_pub_key:
            print "Key already exits: {}".format(ssh_key.name)

    droplet = Droplet()
    droplet.name = "webserver"

    for counter, image in enumerate(images):
        if "Wordpress" in image.name:
            mona = 1