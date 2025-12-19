from flytekit import task, workflow, Resources
import pandas as pd
from typing import NamedTuple

# Define resource limits for the training task (runs on CPU or mild GPU)
@task(
    cache=True, 
    cache_version="1.0",
    requests=Resources(cpu="2", mem="4Gi"),
    limits=Resources(cpu="4", mem="8Gi")
)
def train_model(hyperparameters: dict) -> NamedTuple("outputs", model_artifact=str, metrics=dict):
    """
    Mock training task that replicates a heavy ML job.
    """
    print(f"Training with {hyperparameters}")
    # ... Real training logic would go here ...
    return "s3://my-bucket/models/v1/model.pkl", {"accuracy": 0.95}

@workflow
def mlops_training_workflow(lr: float = 0.01, batch_size: int = 32):
    """
    End-to-End MLOps Workflow: Train -> Evaluate.
    """
    model, metrics = train_model(hyperparameters={"lr": lr, "batch_size": batch_size})
    # Add registration steps here
