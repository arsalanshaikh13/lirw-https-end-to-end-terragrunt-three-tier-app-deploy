output "lirw_bucket_name" {
  value = aws_s3_bucket.bucket.id
}

output "debug_files" {
  value = {
    # upload_folder   = local.upload_folder
    upload_folders_local = local.upload_folders
    upload_folders_var   = var.upload_folder_with_terragrunt
    all_files_count      = length(local.all_files)
    # files_to_uploads = local.files_to_upload
    #  folder           = local.upload_folder
  }
}