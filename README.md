# Serverless Color Palette Generator

A serverless application that generates color palettes and thumbnails from uploaded images using AWS S3, EventBridge, SQS, and Lambda.

## Project Status

**Phase 1: Event Infrastructure (Current)** ✅  
S3 bucket with EventBridge fan-out to multiple SQS queues for parallel processing.

**Phase 2: Processing Lambdas (Upcoming)**  
Lambda functions to generate color palettes and thumbnails from S3 events.

**Phase 3: API & Frontend (Planned)**  
User interface for uploading images and viewing results.

## Architecture

```
User uploads image
        ↓
    S3 Bucket
        ↓
   EventBridge (fan-out)
        ↓
    ┌───────┴───────┐
    ↓               ↓
Palette Queue   Thumbnail Queue
    ↓               ↓
  [Lambda]        [Lambda]  ← Coming in Phase 2
```

### Why This Design?

- **EventBridge fan-out**: Allows a single S3 upload event to trigger multiple independent processing pipelines
- **SQS queues**: Decouples event generation from processing, provides retry logic and rate limiting
- **Separate queues**: Palette and thumbnail generation can scale independently

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- AWS CLI configured with appropriate credentials
- An AWS account with permissions to create S3, SQS, and EventBridge resources

## Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/YOUR-USERNAME/serverless-color-palette.git
   cd serverless-color-palette
   ```

2. **Configure variables**
   
   Create a `terraform.tfvars` file:
   ```hcl
   bucket_name   = "your-unique-bucket-name"
   force_destroy = true  # Set to false in production
   ```

3. **Initialize Terraform**
   ```bash
   terraform init
   ```

4. **Review the plan**
   ```bash
   terraform plan
   ```

5. **Deploy**
   ```bash
   terraform apply
   ```

## Testing

Upload a file to the S3 bucket:

```bash
aws s3 cp test-image.jpg s3://your-bucket-name/
```

Check that messages appear in both queues:

```bash
# Palette queue
aws sqs receive-message --queue-url $(terraform output -raw palette_queue_url)

# Thumbnail queue
aws sqs receive-message --queue-url $(terraform output -raw thumbnail_queue_url)
```

## Resources Created

- **S3 Bucket**: Stores uploaded images
- **S3 Bucket Notification**: Sends events to EventBridge
- **EventBridge Rule**: Matches S3 object creation events
- **SQS Queues** (2): Separate queues for palette and thumbnail processing
- **IAM Policies**: Allows EventBridge to send messages to SQS

## Configuration

### Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `bucket_name` | S3 bucket name (must be globally unique) | Required |
| `force_destroy` | Allow bucket deletion even with objects | `false` |

### Queue Settings

Both queues are configured with:
- **Visibility timeout**: 60 seconds
- **Message retention**: 14 days (1,209,600 seconds)

Adjust these in `main.tf` based on your processing requirements.

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Note**: If `force_destroy = false`, you'll need to empty the S3 bucket manually before destroying.

## Project Structure

```
.
├── main.tf           # Main Terraform configuration
├── variables.tf      # Input variables
├── outputs.tf        # Output values
├── terraform.tfvars  # Variable values (not committed)
└── README.md         # This file
```

## Known Limitations

- No encryption at rest configured (add in production)
- No DLQ (dead letter queue) configured for failed messages
- Visibility timeout may need adjustment based on actual processing time

## Contributing

This is a personal learning project, but suggestions and improvements are welcome via issues or pull requests.

## License

MIT
