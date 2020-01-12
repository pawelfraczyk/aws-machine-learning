data "template_file" "init" {
  template = "${file("${path.module}/templates/init.tpl")}"
}

resource "aws_instance" "kinesis_stream_ec2" {
    ami           = "ami-0d4c3eabb9e72650a"
    instance_type = "t2.micro"
    iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
    user_data = data.template_file.init.rendered

    tags = {
        Name = "KinesisStreamEc2"
    }

    depends_on = [aws_iam_instance_profile.ec2_instance_profile]
}

resource "aws_iam_role" "ec2_instance_role" {
  name               = "iam-ec2-instance-role"
  assume_role_policy = file("${path.module}/iam-policies/ec2-instance-trust.json")
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  role = aws_iam_role.ec2_instance_role.name
  name = "iam-ec2-instance-profile"

  depends_on = [aws_iam_role.ec2_instance_role]
}

data "template_file" "custom_policy_actions" {
  template = file("${path.module}/iam-policies/ec2-instance-role-policy.json")
}

resource "aws_iam_policy" "custom_policy_actions" {
  name       = "iam-custom-policy-actions"
  policy     = data.template_file.custom_policy_actions.rendered
  depends_on = [data.template_file.custom_policy_actions]
}

resource "aws_iam_role_policy_attachment" "attach_custom_policy" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = aws_iam_policy.custom_policy_actions.arn
  depends_on = [aws_iam_role.ec2_instance_role]
}