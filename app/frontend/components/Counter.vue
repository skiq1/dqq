<template>
  <div class="card">
    <div class="card-body">
      <h5>Counter: {{ count }}</h5>
      <button @click="increment" class="btn btn-primary">+</button>
      <button @click="decrement" class="btn btn-secondary">-</button>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'

const count = ref(0)

const increment = () => count.value++
const decrement = () => count.value--
</script>

<style scoped>
.card {
  margin: 20px 0;
}
</style>
