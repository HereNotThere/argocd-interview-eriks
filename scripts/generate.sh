if [ -z "$ENV" ]; then
  echo "ENV is not set"
  exit 1
fi

echo "Generating values for $ENV"

python ./templates/environment.py \
  --params "./environments/${ENV}/source.yaml" \
  --destination "./environments/${ENV}/rendered" \
  --templates "./templates"