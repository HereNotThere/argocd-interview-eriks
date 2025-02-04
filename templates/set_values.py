import argparse
import os
from ruamel.yaml import YAML

def update_yaml(file_path, updates):
    yaml = YAML()
    yaml.preserve_quotes = True  # Preserve original formatting

    with open(file_path, 'r') as file:
        data = yaml.load(file)

    # Apply updates only if the key exists
    for key, value in updates.items():
        keys = key.split('.')  # Support dot notation for nested keys
        d = data

        # Traverse the hierarchy, but stop if a key is missing
        for k in keys[:-1]:
            if k not in d or not isinstance(d[k], dict):
                error_msg = f"Skipping update: '{k}' not found on the original file."
                print(error_msg)
                # exit the program with an error
                exit(1)
            d = d[k]

        else:  # This `else` belongs to the `for` loop (runs if loop wasn't broken)
            if keys[-1] in d:
                d[keys[-1]] = value
            else:
                error_msg = f"Skipping update: '{keys[-1]}' not found on the original file."
                print(error_msg)
                # exit the program with an error

    # Write back only if changes were made
    with open(file_path, 'w') as file:
        yaml.dump(data, file)


def parse_command_line():
    parser = argparse.ArgumentParser(description='Update the root values.yaml file')
    parser.add_argument('--file', required=True, help='Parameters file')

    # add the "set" argument, which is a list of key value pairs like so:
    # --set key1=value1 --set nested.key=value2 
    parser.add_argument('--set', nargs='*', help='Set key value pairs', )
    
    return parser.parse_args()

def get_key_value_pairs(args):
  key_value_pairs = {}
  for pair in args.set:
    key, value = pair.split('=')
    key = key.strip()
    value = value.strip()
    key_value_pairs[key] = value
  return key_value_pairs

def run():
  args = parse_command_line()
  key_value_pairs = get_key_value_pairs(args)

  # if the file does not exist, exit with an error
  if not os.path.exists(args.file):
    print(f'File {args.file} does not exist')
    exit(1)

  # Example usage
  update_yaml(args.file, key_value_pairs)


run()