from yaml import load

try:
    from yaml import CLoader as Loader, CDumper as Dumper
except ImportError:
    from yaml import Loader, Dumper


base_path = "/home/eric/Desktop/aptos/secret/"

def get_private_key(project):
    config = get_config(project)
    return config['profiles']['default']['private_key'][2:]

def get_public_key(project):
    config = get_config(project)
    return config['profiles']['default']['public_key']

def get_config(project):
    base_directory_name = '.aptos_'
    project_secret_directory = base_path + base_directory_name + project
    f = open(project_secret_directory + "/config.yaml")
    config = load(f, Loader=Loader)
    f.close()
    return config

def get_account(project):
    config = get_config(project)
    return config['profiles']['default']['account']


if __name__ == "__main__":
    get_private_key("mobius")
    
