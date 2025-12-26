moved {
  from = aws_vpc.main
  to   = aws_vpc.lornu_vpc
}

moved {
  from = module.eks
  to   = module.lornu_cluster
}
