project_name = input("What is the name of the project? ")
region_name = input("Region name? ")
resource_group = "rg-" + project_name + "-" + region_name
print("Resource group: " + resource_group)
print("Name lenght:", len(resource_group))