import argparse
from jinja2 import Environment, BaseLoader
import yaml
from yaml import dump, Dumper

class MyDumper(Dumper):
    def increase_indent(self, flow=False, indentless=False):
        return super(MyDumper, self).increase_indent(flow, False)

def to_yaml(data):
    return dump(data, Dumper=MyDumper)
  
def parse_command_line():
    parser = argparse.ArgumentParser(description='Generate environment values.yaml')
    parser.add_argument('--params', required=True, help='Parameters file')
    parser.add_argument('--destination', required=True, help='Destination file')
    parser.add_argument('--template', required=True, help='Template file')
    return parser.parse_args()

def run():

  args = parse_command_line()

  with open(args.params, 'r') as f:
      params = yaml.load(f, Loader=yaml.FullLoader)
      
  with open(args.template, 'r') as f:
      template_str = f.read()

  environment = Environment(loader=BaseLoader)
  environment.filters.update({'to_yaml': to_yaml})

  template = environment.from_string(template_str)
  values = template.render(params)

  with open(args.destination, 'w') as f:
      f.write(values)

run()