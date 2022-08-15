package net.fabricmc.example.mixin;

import net.fabricmc.example.ExampleMod;

import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.Redirect;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

import net.minecraft.screen.ScreenHandler;
import net.minecraft.item.ItemStack;
import net.minecraft.item.Items;

@Mixin(ScreenHandler.class)
public class MixinScreenHandler {
    @Inject(
            method = "setStackInSlot(IILnet/minecraft/item/ItemStack;)V",
            at = @At("HEAD")
    )
    private void setStackInSlot(int slot, int revision, ItemStack stack, CallbackInfo ci) {
        if ( ExampleMod.LOGGER != null ){
            if ( slot == 0 && stack != null && stack.getCount() == 0 && stack.getItem().equals(Items.AIR) ) {
                return;
            }
            ExampleMod.LOGGER.info("[d] setStackInSlot(" + slot + ", " + revision + ", " + stack + ") syncId=" + ((ScreenHandler)(Object)this).syncId);
        }
    }
}
