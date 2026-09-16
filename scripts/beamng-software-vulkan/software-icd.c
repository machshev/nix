#include <dlfcn.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <vulkan/vulkan.h>

/* BeamNG ignores CPU devices even when they implement the required features.
 * Forward everything to lavapipe, changing only its reported device type. */
static pthread_once_t once = PTHREAD_ONCE_INIT;
static void *driver;
static PFN_vkGetInstanceProcAddr get_proc;
static PFN_vkGetPhysicalDeviceProperties properties;
static PFN_vkGetPhysicalDeviceProperties2 properties2;

static void initialize(void) {
    driver = dlopen("/run/opengl-driver/lib/libvulkan_lvp.so", RTLD_NOW | RTLD_LOCAL);
    if (!driver) {
        fprintf(stderr, "BeamNG software Vulkan: %s\n", dlerror());
        abort();
    }
    get_proc = (PFN_vkGetInstanceProcAddr)dlsym(driver, "vk_icdGetInstanceProcAddr");
    if (!get_proc) abort();
}

static void report_gpu(VkPhysicalDeviceProperties *p) {
    if (p->deviceType == VK_PHYSICAL_DEVICE_TYPE_CPU)
        p->deviceType = VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU;
}

static VKAPI_ATTR void VKAPI_CALL wrapped_properties(
    VkPhysicalDevice device, VkPhysicalDeviceProperties *p) {
    properties(device, p);
    report_gpu(p);
}

static VKAPI_ATTR void VKAPI_CALL wrapped_properties2(
    VkPhysicalDevice device, VkPhysicalDeviceProperties2 *p) {
    properties2(device, p);
    report_gpu(&p->properties);
}

VKAPI_ATTR PFN_vkVoidFunction VKAPI_CALL vk_icdGetInstanceProcAddr(
    VkInstance instance, const char *name) {
    pthread_once(&once, initialize);
    PFN_vkVoidFunction fn = get_proc(instance, name);
    if (!fn) return NULL;
    if (!strcmp(name, "vkGetPhysicalDeviceProperties")) {
        properties = (PFN_vkGetPhysicalDeviceProperties)fn;
        return (PFN_vkVoidFunction)wrapped_properties;
    }
    if (!strcmp(name, "vkGetPhysicalDeviceProperties2") ||
        !strcmp(name, "vkGetPhysicalDeviceProperties2KHR")) {
        properties2 = (PFN_vkGetPhysicalDeviceProperties2)fn;
        return (PFN_vkVoidFunction)wrapped_properties2;
    }
    return fn;
}

VKAPI_ATTR PFN_vkVoidFunction VKAPI_CALL vk_icdGetPhysicalDeviceProcAddr(
    VkInstance instance, const char *name) {
    pthread_once(&once, initialize);
    if (!strcmp(name, "vkGetPhysicalDeviceProperties") ||
        !strcmp(name, "vkGetPhysicalDeviceProperties2") ||
        !strcmp(name, "vkGetPhysicalDeviceProperties2KHR"))
        return vk_icdGetInstanceProcAddr(instance, name);
    PFN_vkGetInstanceProcAddr physical_proc =
        (PFN_vkGetInstanceProcAddr)dlsym(driver, "vk_icdGetPhysicalDeviceProcAddr");
    return physical_proc ? physical_proc(instance, name) : NULL;
}

VKAPI_ATTR VkResult VKAPI_CALL vk_icdNegotiateLoaderICDInterfaceVersion(uint32_t *version) {
    pthread_once(&once, initialize);
    if (*version > 5) *version = 5;
    typedef VkResult (VKAPI_PTR *Negotiate)(uint32_t *);
    Negotiate negotiate = (Negotiate)dlsym(driver, "vk_icdNegotiateLoaderICDInterfaceVersion");
    return negotiate ? negotiate(version) : VK_SUCCESS;
}
