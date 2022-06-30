defmodule CutiepyBroker.JobTimer do
  @moduledoc false
  use GenServer

  @impl true
  def init(_init_arg) do
    :ok = Phoenix.PubSub.subscribe(CutiepyBroker.PubSub, "completed_job")
    :ok = Phoenix.PubSub.subscribe(CutiepyBroker.PubSub, "enqueued_job")
    :ok = Phoenix.PubSub.subscribe(CutiepyBroker.PubSub, "failed_job")
    job_id_to_timer_ref = %{}
    {:ok, job_id_to_timer_ref}
  end

  @impl true
  def handle_info(%{event_type: "completed_job", job_id: job_id}, job_id_to_timer_ref) do
    case job_id_to_timer_ref[job_id] do
      nil ->
        {:noreply, job_id_to_timer_ref}

      timer_ref ->
        Process.cancel_timer(timer_ref)
        job_id_to_timer_ref = Map.delete(job_id_to_timer_ref, job_id)
        {:noreply, job_id_to_timer_ref}
    end
  end

  @impl true
  def handle_info(%{event_type: "enqueued_job", job_id: job_id}, job_id_to_timer_ref) do
    job = CutiepyBroker.Queries.job(%{job_id: job_id})

    case job.job_timeout_ms do
      nil ->
        {:noreply, job_id_to_timer_ref}

      job_timeout_ms ->
        timer_ref = Process.send_after(self(), {:timeout_job, job_id}, job_timeout_ms)
        job_id_to_timer_ref = Map.put(job_id_to_timer_ref, job_id, timer_ref)
        {:noreply, job_id_to_timer_ref}
    end
  end

  @impl true
  def handle_info(%{event_type: "failed_job", job_id: job_id}, job_id_to_timer_ref) do
    case job_id_to_timer_ref[job_id] do
      nil ->
        {:noreply, job_id_to_timer_ref}

      timer_ref ->
        Process.cancel_timer(timer_ref)
        job_id_to_timer_ref = Map.delete(job_id_to_timer_ref, job_id)
        {:noreply, job_id_to_timer_ref}
    end
  end

  @impl true
  def handle_info({:timeout_job, job_id}, job_id_to_timer_ref) do
    {:ok, _event} = CutiepyBroker.Commands.time_out_job(%{job_id: job_id})
    job_id_to_timer_ref = Map.delete(job_id_to_timer_ref, job_id)
    {:noreply, job_id_to_timer_ref}
  end

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg)
  end
end
