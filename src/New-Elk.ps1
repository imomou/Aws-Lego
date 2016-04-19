﻿param(
    $prefix = "https://s3-ap-southeast-2.amazonaws.com/momo-deployment/aws-lego/2/",
    $kp = "prod", #(Read-Host 'Name of Key Pair to user for server instance access'),
    $ami = "ami-6c14310f", #(Read-Host 'AMI ID of Phabricator Web Server (Ubuntu)'),
    $raw = "imomou-logs2", # (Read-Host 'S3 bucket name to hold raw logs'),
    $access = "imomou-access2", # (Read-Host 'S3 bucket name to hold access logs'),
    $tags = @(
        @{"Key" = "Project"; "Value" = "Infrastructure"},
        @{"Key" = "Environment"; "Value" = "Prod"}
    )
)
#ami-6c14310f

.".\Deployment.ps1"


Get-StackLinkParameters -TemplateUrl "$($prefix)basic-blocks/s3-aws-logs.template" -StackParameters @(
    @{"Key" = "RawLogBucketName"; "Value" = "$raw"},
    @{"Key" = "AccessLogBucketName"; "Value" = "$access"}
) | Upsert-StackLink -Tags $tags -StackName "$($tags[1].Value)-LogStuff" | Wait-StackLink

Get-StackLinkParameters -TemplateUrl "$($prefix)basic-blocks/s3-aws-logs.template" -StackParameters @(
    @{"Key" = "RawLogBucketName"; "Value" = "$raw"},
    @{"Key" = "AccessLogBucketName"; "Value" = "$access"},
    @{"Key" = "IsSubscribed"; "Value" = "subscribe"}
) | Upsert-StackLink -Tags $tags -StackName "$($tags[1].Value)-LogStuff" | Wait-StackLink

Get-StackLinkParameters -TemplateUrl "$($prefix)special-blocks/elasticsearch.template" -StackParameters @(
    @{"Key" = "KeyPairName"; "Value" = $kp},
    @{"Key" = "EsClusterAmi"; "Value" = $ami},
    @{"Key" = "SnapshotBucketName"; "Value" = "bc-es-ss1"}
) | Upsert-StackLink -Tags $tags -StackName "$($tags[1].Value)-Elasticsearch" | Wait-StackLink

Get-StackLinkParameters -TemplateUrl "$($prefix)special-blocks/aws-log-stashing.template" -StackParameters @(
    @{"Key" = "KeyPairName"; "Value" = $kp},
    @{"Key" = "UbuntuAmi"; "Value" = $ami}
) | Upsert-StackLink -Tags $tags -StackName "$($tags[1].Value)-Logstash" | Wait-StackLink