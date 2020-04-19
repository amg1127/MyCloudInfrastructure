# How is this directory structured?

* Each subdirectory created here will contain terraform modules describing creation of resources in the IaaS provider referred by subdirectory's name.
* A symbolic link named *active* will refer to the active cloud provider. Therefore, switching cloud provider will require the following procedure:
    * Run `terraform destroy`
    * Change symlink target
    * Run `terraform init -upgrade`
    * Run `terraform plan`
    * Run `terraform apply`
* All terraform modules will share a common set of input and output variables, as described in `<resourceModule>.variables.tf` and `<resourceModule>.outputs.tf`. To maintain interface consistence, these files will respectively be targets of symlinks named `variables.tf` and `outputs.tf` located in each resource's module.
    * Outputs are exported from local variables that are not initialized. Modules are responsible to assign correct values to those local variables once the actual resources are created.
    * To ease reuse, all input variables should be exported as output variables. I don't know why that is not the default behavior...
