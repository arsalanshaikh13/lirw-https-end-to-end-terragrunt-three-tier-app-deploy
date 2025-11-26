# resource "aws_key_pair" "client_key" {
#     key_name = "client_key"
#     public_key = file("./client_key.pub")
# }
# resource "aws_key_pair" "server_key" {
#     key_name = "server_key"
#     public_key = file("./server_key.pub")
# }

# resource "aws_key_pair" "nat-bastion" {
#   key_name   = "nat-bastion-key"
#   public_key = file("./nat-bastion.pub")
# }

resource "aws_key_pair" "client_key" {
  key_name   = "client_key"
  public_key = file("${path.module}/client_key.pub")
  # public_key = file("./client_key.pub")
  # public_key = file("${var.key_path}/client_key.pub")
  # public_key = file("${path.cwd}/client_key.pub")
  # public_key = file("../modules/key/client_key.pub")
}
resource "aws_key_pair" "server_key" {
  key_name   = "server_key"
  public_key = file("${path.module}/server_key.pub")
  # public_key = file("./server_key.pub")
  # public_key = file("${var.key_path}/client_key.pub")
  # public_key = file("${path.cwd}/server_key.pub")
  # public_key = file("../modules/key/server_key.pub")
}
resource "aws_key_pair" "nat-bastion" {
  key_name   = "nat-bastion-key"
  public_key = file("${path.module}/nat-bastion.pub")
  # public_key = file("${var.key_path}/client_key.pub")
  # public_key = file("./nat-bastion.pub")
  # public_key = file("${path.cwd}/nat-bastion.pub")
  # public_key = file("../modules/key/nat-bastion.pub")
}