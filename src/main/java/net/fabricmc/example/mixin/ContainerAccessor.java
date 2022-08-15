package net.fabricmc.example.mixin;

import net.minecraft.screen.slot.Slot;
import net.minecraft.screen.slot.SlotActionType;
import net.minecraft.client.gui.screen.ingame.HandledScreen;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.gen.Accessor;
import org.spongepowered.asm.mixin.gen.Invoker;

@Mixin(HandledScreen.class)
public interface ContainerAccessor {
    @Invoker
    void invokeOnMouseClick(Slot slot, int invSlot, int button, SlotActionType slotActionType);

    @Accessor
    int getX();

    @Accessor
    int getY();
}
