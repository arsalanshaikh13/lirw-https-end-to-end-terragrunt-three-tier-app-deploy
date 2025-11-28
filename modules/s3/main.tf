resource "aws_s3_bucket" "bucket" {
  bucket        = var.bucket_name
  force_destroy = true # optional, deletes objects when destroying


  tags = {
    Name        = "${var.bucket_name}-files"
    Environment = var.environment
  }
}


# Define folder path relative to the module
locals {

  # upload_folders = "${var.upload_folder}"
  # upload_folders = "${path.root}/lirw-three-tier"
  # upload_folders = "../../lirw-three-tier"
  # upload_folders = var.upload_folder
  upload_folders = var.upload_folder_with_terragrunt



  # Collect all files under lirw-three-tier/
  # all_files = fileset(var.upload_folder, "**/*")
  all_files = fileset(local.upload_folders, "**/*")

  # Try multiple patterns  

  # all_files = fileset(var.upload_folder, "**/*")
  # files_to_exclude = ["DbConfig.js"]
  # files_to_exclude = ["DbConfig.js", "nginx.conf"]

  # Force an error if no files found
  # files_count_check = length(local.all_files) > 0 ? true : tobool("ERROR: No files found in ${local.upload_folder}")

  # Exclude dbconfig.js or any file you don't want
  files_to_upload = [
    # for file in local.all_files : file
    # if file != "DbConfig.js" 
    # files_to_upload = [
    for file in local.all_files : file
    # if !contains(local.files_to_exclude, file)
  ]

}


# Upload all filtered files recursively
resource "aws_s3_object" "app_code_upload" {
  for_each = { for file in local.files_to_upload : file => file }

  bucket = aws_s3_bucket.lirw-bucket.id
  # key = "lirw-three-tier/${dirname(each.key)}/${basename(each.key)}"

  # source = "${local.upload_folder}/${each.key}"
  # etag   = filemd5("${local.upload_folder}/${each.key}")
  key = "lirw-three-tier/${each.value}" # keep same folder structure
  # source = "../../lirw-three-tier/${each.value}"
  # source = "${local.upload_folder}/${each.value}"
  source = "${local.upload_folders}/${each.value}"
  etag   = filemd5("${local.upload_folders}/${each.value}")
  # etag   = filemd5("${local.upload_folder}/${each.value}")
  # etag   = filemd5("../../lirw-three-tier/${each.value}")

  acl = "private"
}


# # Define folder path relative to the module
# locals {
#   upload_folder = "${path.root}/application-code/web-tier"

#   # Collect all files under application-code/
#   all_files = fileset(local.upload_folder, "**")

#   # Exclude dbconfig.js or any file you don't want
#   files_to_upload = [
#     for file in local.all_files : file 
#   ]
# }

# # Upload all filtered files recursively
# resource "aws_s3_object" "web_code_upload" {
#   for_each = { for file in local.files_to_upload : file => file }

#   bucket = aws_s3_bucket.panda-bucket.id
#   key = "application-code/web-tier/${basename(each.key)}"
#   source = "${local.upload_folder}/${each.key}"
#   etag   = filemd5("${local.upload_folder}/${each.key}")
# }


# locals {
#   web = "website2.0"

#   upload_folder = "/mnt/c/Users/DELL/ArsVSCode/CS50p_project/project_aFinal/website/${local.web}/animations/scroll/aws_three_tier_arch/lirw-three-tier/folder-based-project/lirw-three-tier"  

#   # Collect all files under lirw-three-tier/
#   all_files = fileset(local.upload_folder, "**/*")


#   files_to_upload = [
#     for file in local.all_files : file
#   ]
