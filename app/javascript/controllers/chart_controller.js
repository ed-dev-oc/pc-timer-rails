import { Controller } from "@hotwired/stimulus";
import Chart from "chart.js/auto";

export default class extends Controller {
  static targets = ["revenue", "pcStatus", "sessions", "hourly"];

  connect() {
    this.initRevenueChart();
    this.initPcStatusChart();
    this.initSessionsChart();
    this.initHourlyChart();
  }

  initRevenueChart() {
    const canvas = this.revenueTarget;
    if (!canvas || canvas.chart) return;

    const labels = JSON.parse(canvas.dataset.labels);
    const data = JSON.parse(canvas.dataset.data);

    canvas.chart = new Chart(canvas, {
      type: "line",
      data: {
        labels: labels,
        datasets: [
          {
            label: "Revenue (₱)",
            data: data,
            borderColor: "#198754",
            backgroundColor: "rgba(25, 135, 84, 0.1)",
            fill: true,
            tension: 0.4,
            pointRadius: 4,
            pointHoverRadius: 6,
          },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false },
        },
        scales: {
          y: {
            beginAtZero: true,
            ticks: {
              callback: (value) => "₱" + value.toLocaleString(),
            },
          },
        },
      },
    });
  }

  initPcStatusChart() {
    const canvas = this.pcStatusTarget;
    if (!canvas || canvas.chart) return;

    const labels = JSON.parse(canvas.dataset.labels);
    const data = JSON.parse(canvas.dataset.data);

    canvas.chart = new Chart(canvas, {
      type: "doughnut",
      data: {
        labels: labels,
        datasets: [
          {
            data: data,
            backgroundColor: [
              "#198754",
              "#0d6efd",
              "#dc3545",
              "#ffc107",
              "#6c757d",
            ],
          },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { position: "bottom" },
        },
      },
    });
  }

  initSessionsChart() {
    const canvas = this.sessionsTarget;
    if (!canvas || canvas.chart) return;

    const labels = JSON.parse(canvas.dataset.labels);
    const data = JSON.parse(canvas.dataset.data);

    canvas.chart = new Chart(canvas, {
      type: "bar",
      data: {
        labels: labels,
        datasets: [
          {
            label: "Sessions",
            data: data,
            backgroundColor: "#0d6efd",
            borderRadius: 4,
          },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false },
        },
        scales: {
          y: {
            beginAtZero: true,
            ticks: { stepSize: 1 },
          },
        },
      },
    });
  }

  initHourlyChart() {
    const canvas = this.hourlyTarget;
    if (!canvas || canvas.chart) return;

    const labels = JSON.parse(canvas.dataset.labels);
    const data = JSON.parse(canvas.dataset.data);

    canvas.chart = new Chart(canvas, {
      type: "bar",
      data: {
        labels: labels,
        datasets: [
          {
            label: "Sessions",
            data: data,
            backgroundColor: "#6f42c1",
            borderRadius: 4,
          },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false },
        },
        scales: {
          y: {
            beginAtZero: true,
            ticks: { stepSize: 1 },
          },
          x: {
            ticks: { maxRotation: 45 },
          },
        },
      },
    });
  }
}
