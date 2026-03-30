# Add new Secret-Files
go to repo home and execute
```
sops --encrypt --input-type dotenv --output-type dotenv --output .\applications\auth\secrets.sops.env .\applications\auth\secrets.env
```